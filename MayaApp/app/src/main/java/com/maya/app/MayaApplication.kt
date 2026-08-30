package com.maya.app

import android.app.Application
import android.content.Context
import com.maya.app.api.ApiClient
import com.maya.app.api.AuthManager
import com.maya.app.repository.DataRepository
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob

class MayaApplication : Application() {

    override fun onCreate() {
        super.onCreate()
        instance = this
        
        // Initialize auth manager
        AuthManager.initialize(this)
        
        // Initialize API client
        ApiClient.initialize(this)
        
        // Initialize data repository
        DataRepository.initialize(this)
    }

    companion object {
        @Suppress("UNUSED_PARAMETER")
        lateinit var instance: MayaApplication
            private set

        fun getInstance(): MayaApplication = instance
        
        fun getContext(): Context = instance.applicationContext
    }

    // Global coroutine scope for app lifecycle
    val appScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
}
