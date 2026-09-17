package com.maya.app.repository

import android.content.Context

class DataRepository private constructor(
    private val context: Context
) {
    companion object {
        @Suppress("UNUSED_PARAMETER")
        private var instance: DataRepository? = null

        fun initialize(context: Context) {
            if (instance == null) {
                instance = DataRepository(context)
            }
        }

        fun getInstance(): DataRepository = instance!!
    }

    // Stub methods for future implementation
    suspend fun getUserProfile(): String = "{}"
    suspend fun saveUserProfile(data: String) {}
    suspend fun clearUserData() {}
}
