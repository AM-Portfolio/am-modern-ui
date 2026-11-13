/// Import holdings source tab kind (Email vs Document upload).
enum ImportSourceKind { email, upload }

/// Maps route / deep-link slugs to the Email vs Upload tab.
///
/// Mailbox / email-extractor open Email on **all** platforms (web + mobile).
/// Native Gmail connect uses the system browser + status polling.
ImportSourceKind resolveImportSourceSlug(String slug) {
  switch (slug) {
    case 'doc-processor':
    case 'upload':
      return ImportSourceKind.upload;
    case 'email-extractor':
    case 'mailbox':
    default:
      return ImportSourceKind.email;
  }
}
