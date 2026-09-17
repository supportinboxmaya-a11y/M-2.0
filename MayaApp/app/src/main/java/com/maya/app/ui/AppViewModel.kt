package com.maya.app.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.maya.app.api.AuthManager
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class AppViewModel : ViewModel() {
    private val _isLoggedIn = MutableStateFlow(false)
    val isLoggedIn = _isLoggedIn.asStateFlow()

    init {
        checkAuth()
    }

    private fun checkAuth() {
        viewModelScope.launch {
            _isLoggedIn.value = AuthManager.getInstance().isLoggedIn()
        }
    }

    fun login() {
        // TODO: Navigate to login
    }

    fun logout() {
        viewModelScope.launch {
            AuthManager.getInstance().clearTokens()
            _isLoggedIn.value = false
        }
    }
}
