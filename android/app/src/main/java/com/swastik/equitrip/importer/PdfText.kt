package com.swastik.equitrip.importer

import android.content.Context
import android.net.Uri
import com.tom_roush.pdfbox.android.PDFBoxResourceLoader
import com.tom_roush.pdfbox.pdmodel.PDDocument
import com.tom_roush.pdfbox.text.PDFTextStripper
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * Pulls readable text out of a picked PDF — iOS `PDFReader`.
 *
 * PdfBox rather than the platform: `PdfRenderer` only draws pages, and its text API needs
 * Android 15. Sorting by position matters here — booking PDFs are tables, and unsorted
 * extraction interleaves the columns.
 */
object PdfText {
    suspend fun read(context: Context, uri: Uri): String = withContext(Dispatchers.IO) {
        PDFBoxResourceLoader.init(context.applicationContext)
        val raw = try {
            context.contentResolver.openInputStream(uri)?.use { stream ->
                PDDocument.load(stream).use { document ->
                    PDFTextStripper().apply { sortByPosition = true }.getText(document)
                }
            } ?: throw ImportException("That file couldn't be opened.")
        } catch (e: ImportException) {
            throw e
        } catch (e: Exception) {
            throw ImportException("That file couldn't be opened as a PDF.")
        }
        val text = raw.trim()
        if (text.length <= 40) throw ImportException("This PDF has no selectable text — it's likely a scan.")
        // Tables leave runs of spaces and blank lines; collapsing them saves the model context.
        text.replace(Regex("[ \\t]+"), " ")
            .replace(Regex("\\n{3,}"), "\n\n")
            .replace(Regex(" *\\n *"), "\n")
    }
}
