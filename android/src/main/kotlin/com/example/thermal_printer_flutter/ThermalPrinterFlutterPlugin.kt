package com.example.thermal_printer_flutter

import android.Manifest
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothSocket
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.OutputStream
import java.util.UUID
import io.flutter.plugin.common.PluginRegistry

private const val TAG = "THERMAL_PRINTER_FLUTTER"
private const val SPP_UUID = "00001101-0000-1000-8000-00805F9B34FB"
private const val BLUETOOTH_PERMISSION_REQUEST_CODE = 1
private const val BLUETOOTH_ENABLE_REQUEST_CODE = 2

/** ThermalPrinterFlutterPlugin */
class ThermalPrinterFlutterPlugin: FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.RequestPermissionsResultListener, PluginRegistry.ActivityResultListener {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var context: Context
  private lateinit var channel: MethodChannel
  private var bluetoothSocket: BluetoothSocket? = null
  private var outputStream: OutputStream? = null
  private var activity: Activity? = null
  private var pendingResult: Result? = null
  private var pendingBluetoothEnableResult: Result? = null

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
      "checkBluetoothPermissions" -> {
        checkBluetoothPermissions(result)
      }
      "isBluetoothEnabled" -> {
        val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
        result.success(bluetoothAdapter?.isEnabled ?: false)
      }
      "enableBluetooth" -> {
        enableBluetooth(result)
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
      "isConnected" -> {
        val macAddress = call.arguments as? String
        if (macAddress == null) {
          result.error("INVALID_ARGUMENT", "MAC address is required", null)
          return
        }
        isConnected(macAddress, result)
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  private fun checkBluetoothPermissions(result: Result) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      val bluetoothConnect = ContextCompat.checkSelfPermission(
        context,
        Manifest.permission.BLUETOOTH_CONNECT
      )
      val bluetoothScan = ContextCompat.checkSelfPermission(
        context,
        Manifest.permission.BLUETOOTH_SCAN
      )

      if (bluetoothConnect != PackageManager.PERMISSION_GRANTED || 
          bluetoothScan != PackageManager.PERMISSION_GRANTED) {
        pendingResult = result
        activity?.let {
          ActivityCompat.requestPermissions(
            it,
            arrayOf(
              Manifest.permission.BLUETOOTH_CONNECT,
              Manifest.permission.BLUETOOTH_SCAN
            ),
            BLUETOOTH_PERMISSION_REQUEST_CODE
          )
        } ?: run {
          result.error("ACTIVITY_NOT_AVAILABLE", "Activity not available", null)
        }
      } else {
        result.success(true)
      }
    } else {
      // Para Android < 12, precisamos verificar as permissões de localização
      val locationPermission = ContextCompat.checkSelfPermission(
        context,
        Manifest.permission.ACCESS_FINE_LOCATION
      )
      
      if (locationPermission != PackageManager.PERMISSION_GRANTED) {
        pendingResult = result
        activity?.let {
          ActivityCompat.requestPermissions(
            it,
            arrayOf(Manifest.permission.ACCESS_FINE_LOCATION),
            BLUETOOTH_PERMISSION_REQUEST_CODE
          )
        } ?: run {
          result.error("ACTIVITY_NOT_AVAILABLE", "Activity not available", null)
        }
      } else {
        result.success(true)
      }
    }
  }

  private fun enableBluetooth(result: Result) {
    val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
    if (bluetoothAdapter == null) {
      result.error("BLUETOOTH_NOT_AVAILABLE", "Bluetooth is not available on this device", null)
      return
    }

    if (bluetoothAdapter.isEnabled) {
      result.success(true)
      return
    }

    pendingBluetoothEnableResult = result
    activity?.let {
      val enableBtIntent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
      it.startActivityForResult(enableBtIntent, BLUETOOTH_ENABLE_REQUEST_CODE)
    } ?: run {
      result.error("ACTIVITY_NOT_AVAILABLE", "Activity not available", null)
    }
  }

  override fun onRequestPermissionsResult(
    requestCode: Int,
    permissions: Array<out String>,
    grantResults: IntArray
  ): Boolean {
    if (requestCode == BLUETOOTH_PERMISSION_REQUEST_CODE) {
      val allGranted = grantResults.all { it == PackageManager.PERMISSION_GRANTED }
      pendingResult?.success(allGranted)
      pendingResult = null
      return true
    }
    return false
  }

  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
    if (requestCode == BLUETOOTH_ENABLE_REQUEST_CODE) {
      val success = resultCode == Activity.RESULT_OK
      pendingBluetoothEnableResult?.success(success)
      pendingBluetoothEnableResult = null
      return true
    }
    return false
  }

  private fun checkBluetoothPermission(): Boolean {
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      ContextCompat.checkSelfPermission(
        context,
        Manifest.permission.BLUETOOTH_CONNECT
      ) == PackageManager.PERMISSION_GRANTED &&
      ContextCompat.checkSelfPermission(
        context,
        Manifest.permission.BLUETOOTH_SCAN
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

      // Primeiro desconecta qualquer conexão existente
      disconnect(null)

      // Aguarda um momento para garantir que a desconexão foi concluída
      Thread.sleep(500)

      val device = bluetoothAdapter.getRemoteDevice(macAddress)
      bluetoothSocket = device.createRfcommSocketToServiceRecord(UUID.fromString(SPP_UUID))
      
      // Cancela a descoberta de dispositivos para melhorar a estabilidade da conexão
      bluetoothAdapter.cancelDiscovery()
      
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

  private fun isConnected(macAddress: String, result: Result) {
    try {
      val isConnected = bluetoothSocket?.isConnected == true && outputStream != null
      result.success(isConnected)
    } catch (e: Exception) {
      Log.e(TAG, "Error checking connection: ${e.message}")
      result.success(false)
    }
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    binding.addRequestPermissionsResultListener(this)
    binding.addActivityResultListener(this)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
    binding.addRequestPermissionsResultListener(this)
    binding.addActivityResultListener(this)
  }

  override fun onDetachedFromActivity() {
    activity = null
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    disconnect(null)
  }
}
