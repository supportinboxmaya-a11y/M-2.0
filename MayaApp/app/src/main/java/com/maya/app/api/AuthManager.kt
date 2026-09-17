package com.maya.app.api

import android.content.Context
import android.content.SharedPreferences
import com.google.gson.Gson
import com.maya.app.model.AuthTokens
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class AuthManager private constructor(
    private val prefs: SharedPreferences,
    private val gson: Gson
) {
    private val TOKEN_KEY = "auth_tokens"
    private var tokens: AuthTokens? = null
        private set

    companion object {
        @Suppress("UNUSED_PARAMETER")
        private var instance: AuthManager? = null
        
        fun initialize(context: Context) {
            if (instance == null) {
                val prefs = context.getSharedPreferences("maya_auth", Context.MODE_PRIVATE)
                val gson = Gson()
                instance = AuthManager(prefs, gson)
                instance!!.loadTokens()
            }
        }
        
        fun getInstance(): AuthManager = instance!!
    }

    private fun loadTokens() {
        val json = prefs.getString(TOKEN_KEY, null)
        if (json != null) {
            tokens = gson.fromJson(json, AuthTokens::class.java)
        }
    }

    fun saveTokens(newTokens: AuthTokens) {
        tokens = newTokens
        val json = gson.toJson(newTokens)
        prefs.edit().putString(TOKEN_KEY, json).apply()
    }

    fun getAccessToken(): String? = tokens?.accessToken

    fun getRefreshToken(): String? = tokens?.refreshToken

    fun isLoggedIn(): Boolean = tokens != null && tokens!!.accessToken != null

    fun clearTokens() {
        tokens = null
        prefs.edit().remove(TOKEN_KEY).apply()
    }

    suspend fun refreshAccessToken(): Boolean = false // Stub for now
}
