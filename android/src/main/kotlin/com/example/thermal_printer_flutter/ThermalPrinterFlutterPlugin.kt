package com.example.thermal_printer_flutter

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothSocket
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.OutputStream
import java.util.UUID

private const val TAG = "THERMAL_PRINTER_FLUTTER"
private const val SPP_UUID = "00001101-0000-1000-8000-00805F9B34FB"

/** ThermalPrinterFlutterPlugin */
class ThermalPrinterFlutterPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var context: Context
  private lateinit var channel: MethodChannel
  private var bluetoothSocket: BluetoothSocket? = null
  private var outputStream: OutputStream? = null

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    context = flutterPluginBinding.applicationContext
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "thermal_printer_flutter")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "getPlatformVersion" -> {
        result.success("Android ${Build.VERSION.RELEASE}")
      }
      "pairedbluetooths" -> {
        if (!checkBluetoothPermission()) {
          result.error("PERMISSION_DENIED", "Bluetooth permission not granted", null)
          return
        }
        result.success(getPairedDevices())
      }
      "connect" -> {
        if (!checkBluetoothPermission()) {
          result.error("PERMISSION_DENIED", "Bluetooth permission not granted", null)
          return
        }
        val macAddress = call.arguments as? String
        if (macAddress == null) {
          result.error("INVALID_ARGUMENT", "MAC address is required", null)
          return
        }
        connectToDevice(macAddress, result)
      }
      "writebytes" -> {
        if (!checkBluetoothPermission()) {
          result.error("PERMISSION_DENIED", "Bluetooth permission not granted", null)
          return
        }
        val bytes = call.arguments as? List<Int>
        if (bytes == null) {
          result.error("INVALID_ARGUMENT", "Bytes list is required", null)
          return
        }
        writeBytes(bytes, result)
      }
      "disconnect" -> {
        disconnect(result)
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  private fun checkBluetoothPermission(): Boolean {
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      ContextCompat.checkSelfPermission(
        context,
        Manifest.permission.BLUETOOTH_CONNECT
      ) == PackageManager.PERMISSION_GRANTED
    } else {
      true
    }
  }

  private fun getPairedDevices(): List<String> {
    val devices = mutableListOf<String>()
    val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
    
    if (bluetoothAdapter != null && bluetoothAdapter.isEnabled) {
      bluetoothAdapter.bondedDevices.forEach { device ->
        devices.add("${device.name}#${device.address}")
      }
    }
    
    return devices
  }

  private fun connectToDevice(macAddress: String, result: Result) {
    try {
      val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
      if (bluetoothAdapter == null || !bluetoothAdapter.isEnabled) {
        result.error("BLUETOOTH_DISABLED", "Bluetooth is not enabled", null)
        return
      }

      val device = bluetoothAdapter.getRemoteDevice(macAddress)
      bluetoothSocket = device.createRfcommSocketToServiceRecord(UUID.fromString(SPP_UUID))
      bluetoothSocket?.connect()
      outputStream = bluetoothSocket?.outputStream
      
      result.success(true)
    } catch (e: Exception) {
      Log.e(TAG, "Error connecting to device: ${e.message}")
      disconnect(null)
      result.error("CONNECTION_ERROR", e.message, null)
    }
  }

  private fun writeBytes(bytes: List<Int>, result: Result) {
    try {
      if (outputStream == null) {
        result.error("NOT_CONNECTED", "Not connected to any device", null)
        return
      }

      val byteArray = bytes.map { it.toByte() }.toByteArray()
      outputStream?.write(byteArray)
      outputStream?.flush()
      result.success(true)
    } catch (e: Exception) {
      Log.e(TAG, "Error writing bytes: ${e.message}")
      disconnect(null)
      result.error("WRITE_ERROR", e.message, null)
    }
  }

  private fun disconnect(result: Result?) {
    try {
      outputStream?.close()
      bluetoothSocket?.close()
    } catch (e: Exception) {
      Log.e(TAG, "Error disconnecting: ${e.message}")
    } finally {
      outputStream = null
      bluetoothSocket = null
      result?.success(true)
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    disconnect(null)
  }
}
