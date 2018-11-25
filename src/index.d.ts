export declare class SyntaxHighlighter {
	private _highlightr: Highlightr;

	constructor();

	setThemeTo(theme: string): SyntaxHighlighter;

	highlightCodeAs(code: string, lang: string): NSAttributedString;
}
