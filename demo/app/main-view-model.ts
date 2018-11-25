import { Observable } from "tns-core-modules/data/observable";
import { TextField } from "tns-core-modules/ui/text-field";
import { TextView } from "tns-core-modules/ui/text-view";
// import { Highlightr } from "nativescript-syntax-highlighter/typings/objc!Highlightr.d.ts";
import { SyntaxHighlighter } from "nativescript-syntax-highlighter/syntaxhighlighter.ios.ts";

export class HelloWorldModel extends Observable {
    // private highlightr: Highlightr = Highlightr.alloc().init();
    private syntaxHighlighter: SyntaxHighlighter = new SyntaxHighlighter();
    private tv?: TextView;

    constructor() {
        super();
    }

    onComponentLoaded(args){
        const view: TextView|TextField = <TextView|TextField>args.object;
        console.log("onComponentLoaded");

        switch(view.id){
            case "tv":
                this.tv = view as TextView;
                // HelloWorldModel.applyAttributedText(this.tv!, "whatever");

                this.applySyntaxHighlightedText(
                    this.tv!,
                    `const num = 5;\n\nfunction myFunc(param1){\n\tconsole.log("txt", param1);\n}\n\nmyFunc(num);`,
                    "js"
                );
                break;
        }
    }

    applySyntaxHighlightedText(textView: TextView, text: string, lang: string, theme?: string){
        // if(theme) this.highlightr.setThemeTo(theme);
        // const attributedString: NSAttributedString = this.highlightr.highlightCodeAs(text, lang);

        if(theme) this.syntaxHighlighter.setThemeTo(theme);
        const attributedString: NSAttributedString = this.syntaxHighlighter.highlightCodeAs(text, lang);


        (textView.ios as UITextView).attributedText = attributedString;
    }

    static applyTraditionalAttributedText(textView: TextView, text: string){
        const attributedString: NSAttributedString = NSAttributedString.alloc()
        .initWithStringAttributes(
            text,
            //@ts-ignore
            new NSDictionary(
                [UIColor.purpleColor],
                [NSForegroundColorAttributeName],
            )
        );

        (textView.ios as UITextView).attributedText = attributedString;
    }
}
