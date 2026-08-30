package com.maya.app.ui.dashboard

import androidx.compose.material.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@Composable
fun DashboardView() {
    androidx.compose.material.Surface(
        modifier = androidx.compose.ui.Modifier.fillMaxSize(),
        color = androidx.compose.material.MaterialTheme.colors.background
    ) {
        androidx.compose.foundation.layout.Box(
            modifier = androidx.compose.ui.Modifier.fillMaxSize(),
            contentAlignment = Alignment.Center
        ) {
            androidx.compose.material.Column(
                horizontalAlignment = Alignment.CenterHorizontal,
                verticalArrangement = androidx.compose.foundation.layout.Arrangement.Center
            ) {
                Text(
                    text = "Dashboard",
                    fontSize = 24.sp,
                    fontWeight = FontWeight.Bold,
                    color = androidx.compose.material.MaterialTheme.colors.onBackground
                )
                androidx.compose.foundation.layout.Spacer(modifier = Modifier.padding(16.dp))
                Text(
                    text = "Income Engine status\nOpportunities • Projects • Activity",
                    fontSize = 16.sp,
                    textAlign = androidx.compose.ui.text.TextAlign.Center,
                    color = androidx.compose.material.MaterialTheme.colors.onSurface.copy(alpha = 0.7f)
                )
            }
        }
    }
}
