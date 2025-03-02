use cairo_lang_defs::plugin::{InlineMacroPlugin, InlinePluginResult, PluginDiagnostic};
use cairo_lang_syntax::node::db::SyntaxGroup;
use cairo_lang_syntax::node::{ast, TypedSyntaxNode};
use num_bigint::BigInt;

use super::unsupported_bracket_diagnostic;

#[derive(Debug)]
pub struct ConstevalIntMacro;

impl InlineMacroPlugin for ConstevalIntMacro {
    fn generate_code(
        &self,
        db: &dyn SyntaxGroup,
        syntax: &ast::ExprInlineMacro,
    ) -> InlinePluginResult {
        let mut diagnostics = vec![];
        let ast::WrappedExprList::ParenthesizedExprList(args) = syntax.arguments(db) else {
            return unsupported_bracket_diagnostic(db, syntax);
        };
        let constant_expression =
            extract_consteval_macro_expression(db, &args.expressions(db), &mut diagnostics);
        if constant_expression.is_none() {
            return InlinePluginResult { code: None, diagnostics };
        }
        let code = compute_constant_expr(db, &constant_expression.unwrap(), &mut diagnostics);
        InlinePluginResult { code: code.map(|x| x.to_string()), diagnostics }
    }
}

/// Extract the actual expression from the consteval_int macro, or fail with diagnostics.
pub fn extract_consteval_macro_expression(
    db: &dyn SyntaxGroup,
    macro_arguments: &ast::ExprList,
    diagnostics: &mut Vec<PluginDiagnostic>,
) -> Option<ast::Expr> {
    let arguments = macro_arguments.elements(db);
    if arguments.len() != 1 {
        diagnostics.push(PluginDiagnostic {
            stable_ptr: macro_arguments.stable_ptr().untyped(),
            message: "consteval_int macro must have a single unnamed argument.".to_string(),
        });
        return None;
    }
    Some(arguments[0].clone())
}

/// Compute the actual value of an integer expression, or fail with diagnostics.
/// This computation handles arbitrary integers, unlike regular Cairo math.
pub fn compute_constant_expr(
    db: &dyn SyntaxGroup,
    value: &ast::Expr,
    diagnostics: &mut Vec<PluginDiagnostic>,
) -> Option<BigInt> {
    match value {
        ast::Expr::Literal(lit) => lit.numeric_value(db),
        ast::Expr::Binary(bin_expr) => match bin_expr.op(db) {
            ast::BinaryOperator::Plus(_) => Some(
                compute_constant_expr(db, &bin_expr.lhs(db), diagnostics)?
                    + compute_constant_expr(db, &bin_expr.rhs(db), diagnostics)?,
            ),
            ast::BinaryOperator::Mul(_) => Some(
                compute_constant_expr(db, &bin_expr.lhs(db), diagnostics)?
                    * compute_constant_expr(db, &bin_expr.rhs(db), diagnostics)?,
            ),
            ast::BinaryOperator::Minus(_) => Some(
                compute_constant_expr(db, &bin_expr.lhs(db), diagnostics)?
                    - compute_constant_expr(db, &bin_expr.rhs(db), diagnostics)?,
            ),
            ast::BinaryOperator::Div(_) => Some(
                compute_constant_expr(db, &bin_expr.lhs(db), diagnostics)?
                    / compute_constant_expr(db, &bin_expr.rhs(db), diagnostics)?,
            ),
            ast::BinaryOperator::Mod(_) => Some(
                compute_constant_expr(db, &bin_expr.lhs(db), diagnostics)?
                    % compute_constant_expr(db, &bin_expr.rhs(db), diagnostics)?,
            ),
            ast::BinaryOperator::And(_) => Some(
                compute_constant_expr(db, &bin_expr.lhs(db), diagnostics)?
                    & compute_constant_expr(db, &bin_expr.rhs(db), diagnostics)?,
            ),
            ast::BinaryOperator::Or(_) => Some(
                compute_constant_expr(db, &bin_expr.lhs(db), diagnostics)?
                    | compute_constant_expr(db, &bin_expr.rhs(db), diagnostics)?,
            ),
            ast::BinaryOperator::Xor(_) => Some(
                compute_constant_expr(db, &bin_expr.lhs(db), diagnostics)?
                    ^ compute_constant_expr(db, &bin_expr.rhs(db), diagnostics)?,
            ),
            _ => {
                diagnostics.push(PluginDiagnostic {
                    stable_ptr: bin_expr.stable_ptr().untyped(),
                    message: "Unsupported binary operator in consteval_int macro".to_string(),
                });
                None
            }
        },
        ast::Expr::Unary(un_expr) => match un_expr.op(db) {
            ast::UnaryOperator::Minus(_) => {
                Some(-compute_constant_expr(db, &un_expr.expr(db), diagnostics)?)
            }
            _ => {
                diagnostics.push(PluginDiagnostic {
                    stable_ptr: un_expr.stable_ptr().untyped(),
                    message: "Unsupported unary operator in consteval_int macro".to_string(),
                });
                None
            }
        },
        ast::Expr::Parenthesized(paren_expr) => {
            compute_constant_expr(db, &paren_expr.expr(db), diagnostics)
        }
        _ => {
            diagnostics.push(PluginDiagnostic {
                stable_ptr: value.stable_ptr().untyped(),
                message: "Unsupported expression in consteval_int macro".to_string(),
            });
            None
        }
    }
}
