package com.example.blacked_flut

import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattServer
import android.bluetooth.BluetoothGattServerCallback
import android.bluetooth.BluetoothGattService
import android.bluetooth.BluetoothManager
import android.content.Context
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import java.util.*

class MainActivity : FlutterActivity() {

    private lateinit var bluetoothManager: BluetoothManager
    private lateinit var gattServer: BluetoothGattServer
    private lateinit var txCharacteristic: BluetoothGattCharacteristic

    private val SERVICE_UUID: UUID = UUID.fromString("bf27730d-860a-4e09-889c-2d8b6a9e0fe8")
    private val CHARACTERISTIC_UUID: UUID = UUID.fromString("7f27fbcf-2862-4b1e-95d5-2b5850836cbe")

    private val CHANNEL = "com.example.blePeripheral"
    private lateinit var gattServer: BluetoothGattServer
    private lateinit var bluetoothGattServer: BluetoothGattServer

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Create the method channel for communication with Flutter
        MethodChannel(flutterEngine!!.dartExecutor, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "startPeripheral") {
                // Start Peripheral function call
                startPeripheral()
                result.success(null) // Indicating successful execution
            } else {
                result.notImplemented()
            }
        }
        
        // Initialize the GATT server and set up services/characteristics
        val bluetoothManager = getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        val bluetoothAdapter = bluetoothManager.adapter
        bluetoothGattServer = bluetoothManager.openGattServer(this, gattServerCallback)

        // Define the characteristics and services
        val serviceUuid = UUID.fromString("your-service-uuid")
        val characteristicUuid = UUID.fromString("your-characteristic-uuid")
        
        val writeCharacteristic = BluetoothGattCharacteristic(
            characteristicUuid,
            BluetoothGattCharacteristic.PROPERTY_WRITE,
            BluetoothGattCharacteristic.PERMISSION_WRITE
        )

        val service = BluetoothGattService(serviceUuid, BluetoothGattService.SERVICE_TYPE_PRIMARY)
        service.addCharacteristic(writeCharacteristic)

        bluetoothGattServer.addService(service)
    }

    private val gattServerCallback = object : BluetoothGattServerCallback() {
        
        // Handle write requests from the central device
        override fun onCharacteristicWriteRequest(
            device: BluetoothDevice,
            requestId: Int,
            characteristic: BluetoothGattCharacteristic,
            preparedWrite: Boolean,
            responseNeeded: Boolean,
            offset: Int,
            value: ByteArray
        ) {
            if (characteristic.uuid == UUID.fromString("your-characteristic-uuid")) {
                // Perform your write logic here with the received value
                val valueStr = String(value) // Convert to string if needed
                Log.d("Peripheral", "Received Write: $valueStr")

                // Optionally, send a response back to the central device
                bluetoothGattServer.sendResponse(
                    device,
                    requestId,
                    BluetoothGatt.GATT_SUCCESS,
                    0,
                    null
                )
            }
        }

        // Handle read requests if needed
        override fun onCharacteristicReadRequest(
            device: BluetoothDevice,
            requestId: Int,
            characteristic: BluetoothGattCharacteristic,
            offset: Int
        ) {
            if (characteristic.uuid == UUID.fromString("your-characteristic-uuid")) {
                val value = "Peripheral Data".toByteArray()
                bluetoothGattServer.sendResponse(
                    device,
                    requestId,
                    BluetoothGatt.GATT_SUCCESS,
                    0,
                    value
                )
            }
        }
    }

    private fun startPeripheral() {
        // Set up Bluetooth GATT server (example code for peripheral setup)
        val bluetoothAdapter = getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        val gattServerCallback = object : BluetoothGattServerCallback() {
            // Implement the necessary callback methods like onCharacteristicReadRequest, onCharacteristicWriteRequest
        }
        gattServer = bluetoothAdapter.openGattServer(this, gattServerCallback)
        
        // You can then configure your GATT services and characteristics
        // Example:
        val characteristic = BluetoothGattCharacteristic(
            UUID.fromString("your-characteristic-uuid"),
            BluetoothGattCharacteristic.PROPERTY_READ or BluetoothGattCharacteristic.PROPERTY_WRITE,
            BluetoothGattCharacteristic.PERMISSION_READ or BluetoothGattCharacteristic.PERMISSION_WRITE
        )
        
        val service = BluetoothGattService(UUID.fromString("your-service-uuid"), BluetoothGattService.SERVICE_TYPE_PRIMARY)
        service.addCharacteristic(characteristic)
        
        gattServer.addService(service)
    }

    private fun initializeGattServer() {
        val gattServerCallback = MyBluetoothGattServerCallback()

        // Open GATT server
        gattServer = bluetoothManager.openGattServer(this, gattServerCallback)

        // Define the characteristic and add it to a service
        txCharacteristic = BluetoothGattCharacteristic(
            CHARACTERISTIC_UUID,
            BluetoothGattCharacteristic.PROPERTY_WRITE or BluetoothGattCharacteristic.PROPERTY_READ,
            BluetoothGattCharacteristic.PERMISSION_WRITE or BluetoothGattCharacteristic.PERMISSION_READ
        )

        val service = BluetoothGattService(SERVICE_UUID, BluetoothGattService.SERVICE_TYPE_PRIMARY)
        service.addCharacteristic(txCharacteristic)

        // Add service to GATT server
        gattServer.addService(service)
    }

    // Custom callback to handle GATT server operations
    private inner class MyBluetoothGattServerCallback : BluetoothGattServerCallback() {

        // Handle characteristic read requests from the client
        override fun onCharacteristicReadRequest(
            device: BluetoothDevice,
            requestId: Int,
            offset: Int,
            characteristic: BluetoothGattCharacteristic
        ) {
            Log.d("Bluetooth", "Read request from device: $device")
            val value = characteristic.value

            // Send the response back to the device that made the request
            gattServer.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, 0, value)
        }

        // Handle characteristic write requests from the client
        override fun onCharacteristicWriteRequest(
            device: BluetoothDevice,
            requestId: Int,
            characteristic: BluetoothGattCharacteristic,
            preparedWrite: Boolean,
            responseNeeded: Boolean,
            offset: Int,
            value: ByteArray
        ) {
            Log.d("Bluetooth", "Write request from device: $device with value: ${value.joinToString()}")
            characteristic.value = value

            // If a response is needed, send it back to the device
            if (responseNeeded) {
                // Sending response with GATT_SUCCESS
                gattServer.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, 0, null)
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        gattServer.close() // Always close the GATT server when done
    }
}