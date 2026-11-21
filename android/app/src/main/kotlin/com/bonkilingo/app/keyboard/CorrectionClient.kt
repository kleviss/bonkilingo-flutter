package com.bonkilingo.app.keyboard

import org.json.JSONObject
import java.io.IOException
import java.net.HttpURLConnection
import java.net.SocketTimeoutException
import java.net.URL
import java.net.UnknownHostException

/** A failed correction, with the message the keyboard shows. */
class CorrectionException(message: String) : Exception(message)

/**
 * Talks to the Bonkilingo backend's POST /api/correct (bonkilingo-backend),
 * like ios/BonkilingoKeyboard/APIClient.swift. No caching; text is only sent
 * when the user taps Correct. Blocking: call it off the main thread.
 */
class CorrectionClient(private val baseUrl: String) {

    /** [token]: the signed-in user's keyboard token; without it the request is anonymous. */
    fun correct(text: String, token: String?): String {
        val connection = try {
            (URL(baseUrl.trimEnd('/') + "/api/correct").openConnection() as HttpURLConnection).apply {
                requestMethod = "POST"
                connectTimeout = 15_000
                readTimeout = 20_000
                useCaches = false
                doOutput = true
                setRequestProperty("Content-Type", "application/json")
                setRequestProperty("Accept", "application/json")
                if (token != null) setRequestProperty("Authorization", "Bearer $token")
            }
        } catch (e: IOException) {
            throw CorrectionException("Couldn't reach Bonkilingo. Try again.")
        }

        try {
            // "auto": keep the text's own language (the server never translates).
            val body = JSONObject().put("text", text).put("language", "auto").toString()
            connection.outputStream.use { it.write(body.toByteArray(Charsets.UTF_8)) }

            val status = connection.responseCode
            val stream = if (status in 200..299) connection.inputStream else connection.errorStream
            val json = stream?.bufferedReader(Charsets.UTF_8)?.use { it.readText() }
                ?.let { runCatching { JSONObject(it) }.getOrNull() }

            val corrected = json?.optString("corrected", "").orEmpty()
            if (status == 200 && corrected.isNotEmpty()) return corrected
            // 4xx messages from the backend are written for users (limits, length, sign-in).
            val error = json?.optString("error", "").orEmpty()
            if (status in 400..499 && error.isNotEmpty()) throw CorrectionException(error)
            throw CorrectionException("Bonkilingo couldn't correct this right now. Try again.")
        } catch (e: SocketTimeoutException) {
            throw CorrectionException("Bonkilingo took too long to answer. Try again.")
        } catch (e: UnknownHostException) {
            throw CorrectionException("You're offline. Check your connection and try again.")
        } catch (e: IOException) {
            throw CorrectionException("Couldn't reach Bonkilingo. Try again.")
        } finally {
            connection.disconnect()
        }
    }
}
