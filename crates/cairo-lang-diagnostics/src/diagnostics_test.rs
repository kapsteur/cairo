use std::sync::Arc;

use cairo_lang_filesystem::db::FilesGroup;
use cairo_lang_filesystem::ids::{FileId, FileKind, FileLongId, VirtualFile};
use cairo_lang_filesystem::span::{TextOffset, TextSpan, TextWidth};
use cairo_lang_filesystem::test_utils::FilesDatabaseForTesting;
use indoc::indoc;
use test_log::test;

use super::{DiagnosticEntry, DiagnosticLocation, DiagnosticsBuilder};

// Test diagnostic.
#[derive(Clone, Debug, Eq, Hash, PartialEq)]
struct SimpleDiag {
    file_id: FileId,
}
impl DiagnosticEntry for SimpleDiag {
    type DbType = dyn FilesGroup;

    fn format(&self, _db: &dyn cairo_lang_filesystem::db::FilesGroup) -> String {
        "Simple diagnostic.".into()
    }

    fn location(&self, _db: &dyn cairo_lang_filesystem::db::FilesGroup) -> DiagnosticLocation {
        DiagnosticLocation {
            file_id: self.file_id,
            span: TextSpan {
                start: TextOffset::default().add_width(TextWidth::new_for_testing(0)),
                end: TextOffset::default().add_width(TextWidth::new_for_testing(6)),
            },
        }
    }
}

fn setup() -> (FilesDatabaseForTesting, FileId) {
    let db_val = FilesDatabaseForTesting::default();
    let file_id = db_val.intern_file(FileLongId::Virtual(VirtualFile {
        parent: None,
        name: "dummy_file.sierra".into(),
        content: Arc::new("abcd\nefg.\n".into()),
        kind: FileKind::Module,
    }));
    (db_val, file_id)
}

#[test]
fn test_diagnostics() {
    let (db_val, file_id) = setup();

    let mut diagnostics: DiagnosticsBuilder<SimpleDiag> = DiagnosticsBuilder::default();
    let diagnostic = SimpleDiag { file_id };
    diagnostics.add(diagnostic);

    assert_eq!(
        diagnostics.build().format(&db_val),
        indoc! { "
            error: Simple diagnostic.
             --> dummy_file.sierra:1:1
            abcd
            ^**^

        " }
    );
}
