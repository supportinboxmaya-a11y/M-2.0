package com.maya.app

import android.app.Application
import android.content.Context
import com.maya.app.api.AuthManager
import com.maya.app.repository.DataRepository
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlin.jvm.JvmStatic

class MayaApplication : Application() {

    override fun onCreate() {
        super.onCreate()
        instance = this
        
        // Initialize auth manager
        AuthManager.initialize(this)
        
        // Initialize data repository
        DataRepository.initialize(this)
    }

    companion object {
        @Suppress("UNUSED_PARAMETER")
        private lateinit var instance: MayaApplication
            private set

        @JvmStatic
        fun getInstance(): MayaApplication = instance

        @JvmStatic
        fun getContext(): Context = instance.applicationContext
    }

    // Global coroutine scope for app lifecycle
    val appScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
}