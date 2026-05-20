import 'dart:html' as html;

void openInBrowser(String url) {
  html.window.open(url, '_blank');
}

void copyToClipboard(String text) {
  html.window.navigator.clipboard?.writeText(text);
}