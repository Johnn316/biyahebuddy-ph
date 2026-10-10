package ph.biyahebuddy.biyahebuddy_ph.sos

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/**
 * Emergency contact numbers for the native SOS. Reads the saved Profile
 * (Dart shared_preferences key "profile_v1") so edits apply right away, and
 * falls back to the list passed when the trigger was enabled.
 */
object SosContacts {
    private const val PREFS = "buddy_sos"
    private const val KEY = "contacts"

    fun save(ctx: Context, contactsJson: String) {
        ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().putString(KEY, contactsJson).apply()
    }

    fun load(ctx: Context): List<String> {
        val fromProfile = runCatching {
            val raw = ctx.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                .getString("flutter.profile_v1", null)
            raw?.let { phones(JSONObject(it).optJSONArray("contacts")) }
        }.getOrNull()
        if (!fromProfile.isNullOrEmpty()) return fromProfile

        val saved = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY, null)
        return runCatching { phones(JSONArray(saved ?: "[]")) }.getOrDefault(emptyList())
    }

    /** The saved driver Profile (Dart key "profile_v1"), or null. */
    fun profile(ctx: Context): JSONObject? = runCatching {
        ctx.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            .getString("flutter.profile_v1", null)
            ?.let { JSONObject(it) }
    }.getOrNull()

    private fun phones(array: JSONArray?): List<String> {
        if (array == null) return emptyList()
        return (0 until array.length())
            .mapNotNull { array.optJSONObject(it)?.optString("phone")?.trim() }
            .filter { it.isNotEmpty() }
    }
}
