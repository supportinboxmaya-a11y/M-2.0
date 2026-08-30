package com.maya.app.api

import com.maya.app.model.AuthTokens
import com.maya.app.model.User
import retrofit2.Response
import retrofit2.http.Body
import retrofit2.http.POST

interface MayaApi {
    @POST("/api/v1/auth/login")
    suspend fun login(@Body request: LoginRequest): Response<AuthTokens>

    @POST("/api/v1/auth/refresh")
    suspend fun refreshToken(@Body refreshToken: String): Response<AuthTokens>

    @POST("/api/v1/auth/logout")
    suspend fun logout(): Response<Unit>

    @POST("/api/v1/auth/refresh")
    suspend fun refreshToken(@Body request: RefreshRequest): Response<AuthTokens>

    @androidx.room.migration.MigrationCallback.OnConflictStrategy
    interface OnConflictStrategy
}

data class LoginRequest(
    val email: String,
    val password: String
)

data class RefreshRequest(
    val refresh_token: String
)

object ApiClient {
    private var instance: ApiClient? = null

    fun initialize(context: android.content.Context) {
        instance = ApiClient()
    }

    fun getInstance(): ApiClient = instance ?: throw IllegalStateException("ApiClient not initialized")

    val authApi: MayaApi = object : MayaApi {
        override suspend fun login(request: LoginRequest): retrofit2.Response<AuthTokens> {
            TODO("Implement login")
        }

        override suspend fun refreshToken(refreshToken: String): retrofit2.Response<AuthTokens> {
            TODO("Implement refreshToken")
        }

        override suspend fun logout(): retrofit2.Response<Unit> {
            TODO("Implement logout")
        }

        override suspend fun refreshToken(request: RefreshRequest): retrofit2.Response<AuthTokens> {
            TODO("Implement refreshToken")
        }
    }
}
