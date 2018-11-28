//
//  CodeAttributedString.swift
//  Pods
//
//  Created by Illanes, J.P. on 4/19/16.
//
//

import Foundation

#if os(OSX)
    import AppKit
#endif

/// Highlighting Delegate
@objc public protocol HighlightDelegate
{
    /**
     If this method returns *false*, the highlighting process will be skipped for this range.
     
     - parameter range: NSRange
     
     - returns: Bool
     */
    @objc optional func shouldHighlight(_ range:NSRange) -> Bool
    
    /**
     Called after a range of the string was highlighted, if there was an error **success** will be *false*.
     
     - parameter range:   NSRange
     - parameter success: Bool
     */
    @objc optional func didHighlight(_ range:NSRange, success: Bool)
}

/// NSTextStorage subclass. Can be used to dynamically highlight code.
@objc(CodeAttributedString)
open class CodeAttributedString : NSTextStorage
{
    /// Internal Storage
    let stringStorage = NSTextStorage()

    /// Highlightr instace used internally for highlighting. Use this for configuring the theme.
    @objc
    public let highlightr: Highlightr
    
    /// This object will be notified before and after the highlighting.
    open var highlightDelegate : HighlightDelegate?

    /**
     Initialize the CodeAttributedString

     - parameter highlightr: The highlightr instance to use. Defaults to `Highlightr()`.

     */
    @objc
    public init(highlightr: Highlightr = Highlightr()!)
    {
        self.highlightr = highlightr
        super.init()
        setupListeners()
    }

    /// Initialize the CodeAttributedString
    @objc
    public override init() {
        self.highlightr = Highlightr()!
        super.init()
        setupListeners()
    }
    
    /// Initialize the CodeAttributedString
    @objc
    required public init?(coder aDecoder: NSCoder)
    {
        self.highlightr = Highlightr()!
        super.init(coder: aDecoder)
        setupListeners()
    }
    
    #if os(OSX)
    /// Initialize the CodeAttributedString
    @objc
    required public init?(pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType)
    {
        self.highlightr = Highlightr()!
        super.init(pasteboardPropertyList: propertyList, ofType: type)
        setupListeners()
    }
    #endif
    
    /// Language syntax to use for highlighting. Providing nil will disable highlighting.
    @objc
    open var language : String?
    {
        didSet
        {
            highlight(NSMakeRange(0, stringStorage.length))
        }
    }
    
    /// Returns a standard String based on the current one.
    @objc
    open override var string: String
    {
        get
        {
            return stringStorage.string
        }
    }
    
    /**
     Returns the attributes for the character at a given index.
     
     - parameter location: Int
     - parameter range:    NSRangePointer
     
     - returns: Attributes
     */
    @objc
    open override func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [AttributedStringKey : Any]
    {
        return stringStorage.attributes(at: location, effectiveRange: range)
    }
    
    /**
     Replaces the characters at the given range with the provided string.
     
     - parameter range: NSRange
     - parameter str:   String
     */
    @objc
    open override func replaceCharacters(in range: NSRange, with str: String)
    {
        stringStorage.replaceCharacters(in: range, with: str)
        self.edited(TextStorageEditActions.editedCharacters, range: range, changeInLength: (str as NSString).length - range.length)
    }
    
    /**
     Sets the attributes for the characters in the specified range to the given attributes.
     
     - parameter attrs: [String : AnyObject]
     - parameter range: NSRange
     */
    @objc
    open override func setAttributes(_ attrs: [AttributedStringKey : Any]?, range: NSRange)
    {
        stringStorage.setAttributes(attrs, range: range)
        self.edited(TextStorageEditActions.editedAttributes, range: range, changeInLength: 0)
    }
    
    /// Called internally everytime the string is modified.
    @objc
    open override func processEditing()
    {
        super.processEditing()
        if language != nil {
            if self.editedMask.contains(.editedCharacters)
            {
                let string = (self.string as NSString)
                let range = string.paragraphRange(for: editedRange)
                highlight(range)
            }
        }
    }

    @objc
    public func highlight(_ range: NSRange)
    {
        if(language == nil)
        {
            return;
        }
        
        if let highlightDelegate = highlightDelegate
        {
            let shouldHighlight : Bool? = highlightDelegate.shouldHighlight?(range)
            if(shouldHighlight != nil && !shouldHighlight!)
            {
                return;
            }
        }

        
        let string = (self.string as NSString)
        let line = string.substring(with: range)
        DispatchQueue.global().async
        {
            let tmpStrg = self.highlightr.highlight(line, as: self.language!)
            DispatchQueue.main.async(execute: {
                //Checks to see if this highlighting is still valid.
                if((range.location + range.length) > self.stringStorage.length)
                {
                    self.highlightDelegate?.didHighlight?(range, success: false)
                    return;
                }
                
                if(tmpStrg?.string != self.stringStorage.attributedSubstring(from: range).string)
                {
                    self.highlightDelegate?.didHighlight?(range, success: false)
                    return;
                }
                
                self.beginEditing()
                tmpStrg?.enumerateAttributes(in: NSMakeRange(0, (tmpStrg?.length)!), options: [], using: { (attrs, locRange, stop) in
                    var fixedRange = NSMakeRange(range.location+locRange.location, locRange.length)
                    fixedRange.length = (fixedRange.location + fixedRange.length < string.length) ? fixedRange.length : string.length-fixedRange.location
                    fixedRange.length = (fixedRange.length >= 0) ? fixedRange.length : 0
                    self.stringStorage.setAttributes(attrs, range: fixedRange)
                })
                self.endEditing()
                self.edited(TextStorageEditActions.editedAttributes, range: range, changeInLength: 0)
                self.highlightDelegate?.didHighlight?(range, success: true)
            })
            
        }
        
    }
    
    @objc
    public func setupListeners()
    {
        highlightr.themeChanged =
            { _ in
                    self.highlight(NSMakeRange(0, self.stringStorage.length))
            }
    }
    
    
}
