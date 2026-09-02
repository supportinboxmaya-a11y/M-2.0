package com.maya.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.viewModels
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.Spacer
import androidx.compose.material.Button
import androidx.compose.material.MaterialTheme
import androidx.compose.material.Surface
import androidx.compose.material.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.maya.app.ui.AppViewModel
import com.maya.app.ui.dashboard.DashboardView

class MainActivity : ComponentActivity() {

    private val viewModel: AppViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Initialize ApiClient with production backend URL
        com.maya.app.api.ApiClient.initialize(this, "http://130.210.46.182:8000/")

        val isLoggedIn by viewModel.isLoggedIn.collectAsStateWithLifecycle(initial = false)

        setContent {
            MaterialTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colors.background
                ) {
                    if (isLoggedIn) {
                        DashboardView()
                    } else {
                        LoginPromptView(onLoginClick = { viewModel.login() })
                    }
                }
            }
        }
    }
}

@Composable
fun LoginPromptView(onLoginClick: () -> Unit) {
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
        androidx.compose.foundation.layout.Spacer(modifier = androidx.compose.foundation.layout.padding(24.dp))
        Text(
            text = "Sign in to access your dashboard",
            fontSize = 16.sp,
            color = MaterialTheme.colors.onSurface.copy(alpha = 0.7f),
            textAlign = TextAlign.Center
        )
        androidx.compose.foundation.layout.Spacer(modifier = androidx.compose.foundation.layout.padding(24.dp))
        androidx.compose.material.Button(
            onClick = onLoginClick,
            modifier = Modifier.fillMaxWidth().padding(horizontal = 32.dp)
        ) {
            Text(text = "Sign In", fontSize = 16.sp)
        }
    }
}