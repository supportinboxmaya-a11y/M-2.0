package com.maya.app.ui

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.Spacer
import androidx.compose.material.Button
import androidx.compose.material.MaterialTheme
import androidx.compose.material.PasswordVisualTransformation
import androidx.compose.material.Surface
import androidx.compose.material.Text
import androidx.compose.material.TextField
import androidx.compose.runtime.Composable
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.maya.app.api.ApiClient
import com.maya.app.api.AuthManager
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class LoginActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colors.background
                ) {
                    LoginScreen(onLoginSuccess = { finish() })
                }
            }
        }
    }
}

@Composable
fun LoginScreen(onLoginSuccess: () -> Unit) {
    val emailState = remember { mutableStateOf("") }
    val passwordState = remember { mutableStateOf("") }
    val isLoadingState = remember { mutableStateOf(false) }
    val errorState = remember { mutableStateOf<String?>(null) }

    Column(
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = "Maya Assistant",
            fontSize = 28.sp,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colors.onBackground
        )
        Spacer(modifier = Modifier.padding(24.dp))

        Text(
            text = "Sign in to your account",
            fontSize = 16.sp,
            color = MaterialTheme.colors.onSurface.copy(alpha = 0.7f),
            textAlign = TextAlign.Center
        )
        Spacer(modifier = Modifier.padding(24.dp))

        TextField(
            value = emailState.value,
            onValueChange = { emailState.value = it },
            label = { Text("Email") },
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 32.dp),
            singleLine = true
        )
        Spacer(modifier = Modifier.padding(16.dp))

        TextField(
            value = passwordState.value,
            onValueChange = { passwordState.value = it },
            label = { Text("Password") },
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 32.dp),
            singleLine = true,
            visualTransformation = PasswordVisualTransformation()
        )

        val error = errorState.value
        if (error != null) {
            Spacer(modifier = Modifier.padding(16.dp))
            Text(
                text = error,
                fontSize = 14.sp,
                color = MaterialTheme.colors.error,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth().padding(horizontal = 32.dp)
            )
        }

        Spacer(modifier = Modifier.padding(24.dp))

        val loading = isLoadingState.value
        Button(
            onClick = {
                val email = emailState.value
                val password = passwordState.value
                if (email.isNotBlank() && password.isNotBlank() && !isLoadingState.value) {
                    isLoadingState.value = true
                    errorState.value = null
                    CoroutineScope(Dispatchers.IO).launch {
                        val result = ApiClient.getInstance().login(emailState.value, passwordState.value)
                        withContext(Dispatchers.Main) {
                            isLoadingState.value = false
                            when {
                                result.isSuccess -> {
                                    AuthManager.getInstance().saveTokens(result.getOrNull()!!)
                                    onLoginSuccess()
                                }
                                result.isFailure -> {
                                    errorState.value = result.exceptionOrNull()?.message ?: "Login failed"
                                }
                            }
                        }
                    }
                },
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 32.dp),
            enabled = !isLoadingState.value
        ) {
            Text(text = if (isLoadingState.value) "Signing in..." else "Sign In", fontSize = 16.sp)
        }

        Spacer(modifier = Modifier.padding(16.dp))

        Text(
            text = "Don't have an account? Create one at maya.ai",
            fontSize = 14.sp,
            color = MaterialTheme.colors.onSurface.copy(alpha = 0.6f),
            textAlign = TextAlign.Center
        )
    }
}