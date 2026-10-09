package ph.biyahebuddy.biyahebuddy_ph.sos

import android.Manifest
import android.content.Context
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Handler
import android.os.Looper
import android.util.Log

/**
 * Location for the native SOS path via android.location.LocationManager only
 * (GPS / network providers). No Google Play Services: works on Huawei.
 */
object SosLocation {
    private const val TAG = "BuddySos"

    /** First fix within [timeoutMs], else the newest last-known fix, else null. */
    fun current(ctx: Context, timeoutMs: Long = 15_000L, done: (Location?) -> Unit) {
        val fine = SosTelephony.granted(ctx, Manifest.permission.ACCESS_FINE_LOCATION)
        val coarse = SosTelephony.granted(ctx, Manifest.permission.ACCESS_COARSE_LOCATION)
        val lm = ctx.getSystemService(LocationManager::class.java)
        if ((!fine && !coarse) || lm == null) return done(null)

        val providers = listOf(LocationManager.GPS_PROVIDER, LocationManager.NETWORK_PROVIDER)
            .filter { runCatching { lm.isProviderEnabled(it) }.getOrDefault(false) }
        if (providers.isEmpty()) return done(lastKnown(lm))

        val handler = Handler(Looper.getMainLooper())
        var finished = false
        lateinit var listener: LocationListener

        fun finish(loc: Location?) {
            if (finished) return
            finished = true
            handler.removeCallbacksAndMessages(null)
            runCatching { lm.removeUpdates(listener) }
            done(loc ?: lastKnown(lm))
        }

        listener = LocationListener { loc -> finish(loc) }
        try {
            for (p in providers) {
                lm.requestLocationUpdates(p, 0L, 0f, listener, Looper.getMainLooper())
            }
        } catch (e: SecurityException) {
            Log.w(TAG, "location permission revoked", e)
            return finish(null)
        }
        handler.postDelayed({ finish(null) }, timeoutMs)
    }

    private fun lastKnown(lm: LocationManager): Location? =
        listOf(
            LocationManager.GPS_PROVIDER,
            LocationManager.NETWORK_PROVIDER,
            LocationManager.PASSIVE_PROVIDER,
        ).mapNotNull {
            try {
                lm.getLastKnownLocation(it)
            } catch (_: Exception) {
                null
            }
        }.maxByOrNull { it.time }
}
