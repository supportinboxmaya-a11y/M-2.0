package com.maya.app.api

import android.content.Context
import com.google.gson.Gson
import com.google.gson.GsonBuilder
import com.maya.app.model.AuthTokens
import com.maya.app.model.LoginRequest
import com.maya.app.model.RefreshRequest
import com.maya.app.model.User
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Response
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import retrofit2.http.Body
import retrofit2.http.Header
import retrofit2.http.POST

interface MayaApi {
    @POST("/api/v1/auth/login")
    suspend fun login(@Body request: LoginRequest): Response<AuthTokens>

    @POST("/api/v1/auth/refresh")
    suspend fun refreshToken(@Body request: RefreshRequest): Response<AuthTokens>

    @POST("/api/v1/auth/logout")
    suspend fun logout(@Header("Authorization") authHeader: String): Response<Unit>
}

class ApiClient private constructor(
    private val api: MayaApi,
    private val authManagerProvider: () -> AuthManager
) {
    companion object {
        @Suppress("UNUSED_PARAMETER")
        @Volatile private var INSTANCE: ApiClient? = null

        fun initialize(context: Context, baseUrl: String = "http://130.210.46.182:8000/") {
            if (INSTANCE == null) {
                synchronized(this) {
                    if (INSTANCE == null) {
                        val loggingInterceptor = HttpLoggingInterceptor().apply {
                            level = HttpLoggingInterceptor.Level.BODY
                        }
                        val okHttpClient = OkHttpClient.Builder()
                            .addInterceptor(loggingInterceptor)
                            .build()

                        val gson = GsonBuilder().setLenient().create()

                        val retrofit = Retrofit.Builder()
                            .baseUrl(baseUrl)
                            .client(okHttpClient)
                            .addConverterFactory(GsonConverterFactory.create(gson))
                            .build()

                        val api = retrofit.create(MayaApi::class.java)
                        // AuthManager is lazily retrieved when needed, not during ApiClient init
                        INSTANCE = ApiClient(api, AuthManager::getInstance)
                    }
                }
            }
        }

        fun getInstance(): ApiClient = INSTANCE ?: throw IllegalStateException("ApiClient not initialized. Call initialize() first.")
    }

    suspend fun login(email: String, password: String): Result<AuthTokens> {
        return try {
            val response = api.login(LoginRequest(email, password))
            if (response.isSuccessful) {
                response.body()?.let { tokens ->
                    authManagerProvider().saveTokens(tokens)
                    Result.success(tokens)
                } ?: Result.failure(Exception("Login response body is null"))
            } else {
                Result.failure(Exception("Login failed: ${response.code()} ${response.message()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun refreshAuthToken(): Boolean {
        val refreshToken = authManagerProvider().getRefreshToken() ?: return false
        return try {
            val response = api.refreshToken(RefreshRequest(refreshToken))
            if (response.isSuccessful) {
                response.body()?.let { tokens ->
                    authManagerProvider().saveTokens(tokens)
                    true
                } ?: false
            } else {
                false
            }
        } catch (e: Exception) {
            false
        }
    }

    suspend fun logout(): Boolean {
        val accessToken = authManagerProvider().getAccessToken() ?: return false
        return try {
            val response = api.logout("Bearer $accessToken")
            if (response.isSuccessful) {
                authManagerProvider().clearTokens()
                true
            } else {
                false
            }
        } catch (e: Exception) {
            false
        }
    }

    fun getAuthApi(): MayaApi = api
    fun getAuthManager(): AuthManager = authManagerProvider()
}