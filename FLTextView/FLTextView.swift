//
//  FLTextView.swift
//  FLTextView
//
//  Created by Danilo Bürger on 07.04.15.
//  Copyright (c) 2015 Freeletics GmbH (https://www.freeletics.com/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import UIKit

public class FLTextView: UITextView {
    
    // MARK: - Private Properties
    
    private let placeholderView = UITextView(frame: CGRectZero)
    
    private weak var externalTextViewDelegate: UITextViewDelegate?
    
    private var canResetTextViewDelegate = false
    
    //Stored default font because it's resets after change attributedString
    private var stroredTextFont: UIFont?
    
    //Stored default text coor because it's resets after change attributedString
    private var stroredTextColor: UIColor?
    
    //Stored placeholder text for preventing editing
    private var stroredPlaceholderText: String?
    
    //Stored placeholder attributed text for preventing editing
    private var stroredAttrPlaceholderText: NSAttributedString?
    
    
    //Default text color
    private let defaultTextColor = UIColor.blackColor()
    
    //Default text color
    private let defaultTextFont = UIFont.systemFontOfSize(UIFont.systemFontSize())
    
    
    // MARK: - Placeholder Properties
    
    //Non-editable and non-delitable prefix which appears after srart typing
    @IBInspectable public var frozenPrefix: String?
    
    //Color for frozen prefix by default uses color of textview text
    @IBInspectable public var frozenPrefixColor: UIColor?
    
    //Font for frozen prefix by default uses font of textview text
    public var frozenPrefixFont: UIFont?
    
    /// If you want to apply the color to only a portion of the placeholder,
    /// you must create a new attributed string with the desired style information
    /// and assign it to the attributedPlaceholder property.
    @IBInspectable public var placeholderTextColor: UIColor? {
        get {
            return placeholderView.textColor
        }
        set {
            placeholderView.textColor = newValue
        }
    }
    
    /// The string that is displayed when there is no other text in the text view.
    @IBInspectable public var placeholder: String? {
        get {
            return placeholderView.text
        }
        set {
            stroredPlaceholderText = newValue
            placeholderView.text = stroredPlaceholderText
            setNeedsLayout()
        }
    }
    
    /// The styled string that is displayed when there is no other text in the text view.
    public var attributedPlaceholder: NSAttributedString? {
        get {
            return placeholderView.attributedText
        }
        set {
            stroredAttrPlaceholderText = newValue
            placeholderView.attributedText = stroredAttrPlaceholderText
            setNeedsLayout()
        }
    }
    
    /// Returns true if the placeholder is currently showing.
    public var isShowingPlaceholder: Bool {
        return placeholderView.superview != nil
    }
    
    public func defaultPlaceholderAttributedStringForFrozenPrefix() -> NSAttributedString? {
        
        guard let frozenText = frozenPrefix, placeholderText = placeholder where placeholderText.characters.count > 0  else { return nil}
        
        let attributedString = NSMutableAttributedString(string: placeholderText)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = textAlignment
        let frozenPrefixColorValue = frozenPrefixColor ?? placeholderTextColor ?? textColor ?? UIColor.grayColor()
        let attrForFrozen = [NSForegroundColorAttributeName: frozenPrefixColorValue, NSFontAttributeName: font!, NSParagraphStyleAttributeName: paragraphStyle]
        let nonFrozenTextColor = placeholderTextColor ?? frozenPrefixColorValue
        let attrForNonFrozen = [NSForegroundColorAttributeName: nonFrozenTextColor, NSFontAttributeName: font!, NSParagraphStyleAttributeName: paragraphStyle]
        
        let rangeOfFrozenText =  NSMakeRange(0, frozenText.characters.count)
        attributedString.addAttributes(attrForFrozen, range: rangeOfFrozenText)
        
        let rangeOfNonFrozenText = NSMakeRange(frozenText.characters.count, placeholderText.characters.count - frozenText.characters.count)
        attributedString.addAttributes(attrForNonFrozen, range: rangeOfNonFrozenText)
        
        return attributedString
    }
    
    
    // MARK: - Delegate
    
    override weak public var delegate: UITextViewDelegate? {
        get {
            return self
        }
        set {
            
            if newValue is FLTextView  == false {
                externalTextViewDelegate = newValue
            }
            
            if !canResetTextViewDelegate {
                super.delegate = self
            }
            
        }
        
    }
    
    
    // MARK: - Observed Properties
    
    override public var text: String! {
        didSet {
            if oldValue.isEmpty {
                applyStylesForFrozenText()
            }
            showPlaceholderViewIfNeeded()
        }
    }
    
    override public var attributedText: NSAttributedString! {
        didSet {
            if oldValue.string.isEmpty {
                applyStylesForFrozenText()
            }
            showPlaceholderViewIfNeeded()
        }
    }
    
    override public var font: UIFont? {
        didSet {
            stroredTextFont = font
            placeholderView.font = font
        }
    }
    
    override public var textColor: UIColor? {
        didSet {
            stroredTextColor = textColor
        }
    }
    
    override public var textAlignment: NSTextAlignment {
        didSet {
            placeholderView.textAlignment = textAlignment
        }
    }
    
    override public var textContainerInset: UIEdgeInsets {
        didSet {
            placeholderView.textContainerInset = textContainerInset
        }
    }
    
    // MARK: - Initialization
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        delegate = self
        setupPlaceholderView()
    }
    
    override public init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        delegate = self
        setupPlaceholderView()
    }
    
    public override func isFirstResponder() -> Bool {
        
        if placeholderView.isFirstResponder() {
            return true
        } else {
            return super.isFirstResponder()
        }
    }
    
    public override func becomeFirstResponder() -> Bool {
        if isShowingPlaceholder && placeholderView.isFirstResponder() {
            return false
        } else {
            applyStylesForFrozenText()
            return super.becomeFirstResponder()
        }
        
    }
    
    public override func resignFirstResponder() -> Bool {
        if placeholderView.isFirstResponder() {
            return placeholderView.resignFirstResponder()
        } else {
            return super.resignFirstResponder()
        }
    }
    
    deinit {
        canResetTextViewDelegate = true
    }
    
    
    // MARK: - UIView
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        resizePlaceholderView()
    }
    
    public override func intrinsicContentSize() -> CGSize {
        if isShowingPlaceholder {
            return placeholderSize()
        }
        return super.intrinsicContentSize()
    }
    
    // MARK: - Placeholder
    
    private func setupPlaceholderView() {
        placeholderView.opaque = false
        placeholderView.backgroundColor = UIColor.clearColor()
        placeholderView.textColor = UIColor(white: 0.7, alpha: 1.0)
        
        placeholderView.editable = true
        placeholderView.scrollEnabled = true
        placeholderView.userInteractionEnabled = false
        placeholderView.isAccessibilityElement = false
        placeholderView.selectable = true
        
        showPlaceholderViewIfNeeded()
        
        placeholderView.delegate = self
    }
    
    private func showPlaceholderViewIfNeeded() {
        if text != nil && !text.isEmpty {
            if isShowingPlaceholder {
                placeholderView.removeFromSuperview()
                invalidateIntrinsicContentSize()
                setContentOffset(CGPointZero, animated: false)
            }
        } else {
            if !isShowingPlaceholder {
                addSubview(placeholderView)
                invalidateIntrinsicContentSize()
                setContentOffset(CGPointZero, animated: false)
            }
        }
    }
    
    private func resizePlaceholderView() {
        if isShowingPlaceholder {
            let frame = self.bounds
            
            if !CGRectEqualToRect(placeholderView.frame, frame) {
                placeholderView.frame = frame
                invalidateIntrinsicContentSize()
            }
            
            contentInset = UIEdgeInsetsMake(0.0, 0.0, frame.height - contentSize.height, 0.0)
            moveCursorAfterFrozenTextIfPossible()
            
        } else {
            contentInset = UIEdgeInsetsZero
        }
    }
    
    private func moveCursorAfterFrozenTextIfPossible() {
        if let frozenText = frozenPrefix {
            placeholderView.userInteractionEnabled = true
            placeholderView.becomeFirstResponder()
            placeholderView.selectedRange = NSMakeRange(frozenText.characters.count, 0)
        }
    }
    
    private func moveCursorAfterFrozenTextIfPossibleInMainTextView() {
        if let frozenText = frozenPrefix where !NSEqualRanges(selectedRange, NSMakeRange(frozenText.characters.count, 0)) && selectedRange.length == 0 && selectedRange.location <= frozenText.characters.count && !(NSEqualRanges(selectedRange, NSMakeRange(0, 0)) && text.characters.count == 0) {
            selectedRange = NSMakeRange(frozenText.characters.count, 0)
        }
    }
    
    private func placeholderSize() -> CGSize {
        var maxSize = self.bounds.size
        maxSize.height = CGFloat.max
        return placeholderView.sizeThatFits(maxSize)
    }
    
    // MARK: - Frozen text
    
    private func applyStylesForFrozenText() {
        guard let frozenText = frozenPrefix, attrText = attributedText where attributedText.length > 0 else { return }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = textAlignment
        
        let isAttributedStringNeed = (frozenPrefixColor != nil || frozenPrefixFont != nil)
        
        let attrForzenFont = (frozenPrefixFont ?? font) ?? defaultTextFont
        let attrForzenColor = (frozenPrefixColor ?? textColor) ?? defaultTextColor
        let attrsFrozen = [NSFontAttributeName : attrForzenFont, NSForegroundColorAttributeName: attrForzenColor, NSParagraphStyleAttributeName : paragraphStyle]
        
        if attrText.string == frozenText && isAttributedStringNeed {
            let attributedString = NSMutableAttributedString(string: "")
            let frozenAttributedString = NSAttributedString(string:frozenText, attributes:attrsFrozen)
            attributedString.appendAttributedString(frozenAttributedString)
            text = nil
            attributedText = attributedString
        } else if isAttributedStringNeed {
            let storedSelectedRange = selectedRange
            let mutableAttributedString = attrText.mutableCopy() as! NSMutableAttributedString
            let attrs = [NSFontAttributeName :stroredTextFont ?? defaultTextFont, NSForegroundColorAttributeName: stroredTextColor ?? defaultTextColor, NSParagraphStyleAttributeName : paragraphStyle]
            let rangeOfNonFrozenText = NSMakeRange(frozenText.characters.count, mutableAttributedString.length - frozenText.characters.count)
            mutableAttributedString.addAttributes(attrs, range: rangeOfNonFrozenText)
            
            let rangeOfFrozenText =  NSMakeRange(0, frozenText.characters.count)
            mutableAttributedString.addAttributes(attrsFrozen, range: rangeOfFrozenText)
            attributedText = mutableAttributedString
            selectedRange = storedSelectedRange
        }
    }
    
    //MARK: Check or external delegate is present and responds to selector
    
    private func isExternalTextViewDelegateRespondsToSelector(selector: Selector) ->Bool {
        guard let extDelegate = externalTextViewDelegate else { return false}
        
        return extDelegate.respondsToSelector(selector)
    }
    
}


//MARK: UITextViewDelegate

extension FLTextView: UITextViewDelegate {
    
    public func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        
        let isDeletedSymbol = text.isEmpty
        
        guard let frozenText = frozenPrefix where textView != placeholderView else {
            
            if textView == placeholderView {
                if isDeletedSymbol { return false }
                
                if let frozenText = frozenPrefix where placeholderView.isFirstResponder() {
                    placeholderView.userInteractionEnabled = false
                    placeholderView.resignFirstResponder()
                    self.text = frozenText + text
                    becomeFirstResponder()
                    if isExternalTextViewDelegateRespondsToSelector(#selector(UITextViewDelegate.textViewDidChange(_:))) {
                        externalTextViewDelegate!.textViewDidChange!(self)
                    }
                    return false
                }
            }
            
            return isExternalTextViewDelegateRespondsToSelector(#selector(UITextViewDelegate.textView(_:shouldChangeTextInRange:replacementText:))) ? externalTextViewDelegate!.textView!(textView, shouldChangeTextInRange: range, replacementText: text) : true
        }
        
        let protectedRange = NSMakeRange(0, frozenText.characters.count)
        let intersection = NSIntersectionRange(protectedRange, range)
        
        let frozenTextLength = frozenText.characters.count
        let lengthOfTextForRange = (textView.text as NSString).length
        let shouldClearFrozenText = isDeletedSymbol && (textView.text.characters.count == frozenTextLength + 1 || (range.location == frozenTextLength && (lengthOfTextForRange - range.length == frozenTextLength))) && intersection.location == 0 && intersection.length == 0
        
        if shouldClearFrozenText {
            textView.text = text
            textViewDidChange(textView)
            return true
        }
        
        if textView.text.characters.count == 0 && frozenPrefix != nil && text != "" {
            textView.text = frozenPrefix
            applyStylesForFrozenText()
            return true
        }
        
        if intersection.length > 0 || intersection.location > 0  || NSLocationInRange(range.location, protectedRange){
            
            return false
        }
        
        return isExternalTextViewDelegateRespondsToSelector(#selector(UITextViewDelegate.textView(_:shouldChangeTextInRange:replacementText:))) ? externalTextViewDelegate!.textView!(textView, shouldChangeTextInRange: range, replacementText: text) : true
    }
    
    public func textViewDidChange(textView: UITextView) {
        guard textView != placeholderView else {
            if stroredAttrPlaceholderText != nil && textView.attributedText != stroredAttrPlaceholderText {
                textView.attributedText = stroredAttrPlaceholderText
            } else if stroredPlaceholderText != nil && textView.text != stroredPlaceholderText {
                textView.text = stroredPlaceholderText
            }
            return
        }
        showPlaceholderViewIfNeeded()
        if isExternalTextViewDelegateRespondsToSelector(#selector(UITextViewDelegate.textViewDidChange(_:))) {
            externalTextViewDelegate!.textViewDidChange!(textView)
        }
        applyStylesForFrozenText()
    }
    
    public func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        guard isExternalTextViewDelegateRespondsToSelector(#selector(UITextViewDelegate.textViewShouldBeginEditing(_:))) else { return true}
        return externalTextViewDelegate!.textViewShouldBeginEditing!(textView)
    }
    
    public func textViewShouldEndEditing(textView: UITextView) -> Bool {
        guard isExternalTextViewDelegateRespondsToSelector(#selector(UITextViewDelegate.textViewShouldEndEditing(_:))) else { return true }
        return externalTextViewDelegate!.textViewShouldEndEditing!(textView)
    }
    
    public func textViewDidBeginEditing(textView: UITextView) {
        guard isExternalTextViewDelegateRespondsToSelector(#selector(UITextViewDelegate.textViewDidBeginEditing(_:))) else { return }
        externalTextViewDelegate!.textViewDidBeginEditing!(textView)
    }
    
    public func textViewDidEndEditing(textView: UITextView) {
        guard isExternalTextViewDelegateRespondsToSelector(#selector(UITextViewDelegate.textViewDidEndEditing(_:))) else { return }
        externalTextViewDelegate!.textViewDidEndEditing!(textView)
    }
    
    public func textViewDidChangeSelection(textView: UITextView) {
        guard textView != placeholderView && isExternalTextViewDelegateRespondsToSelector(#selector(UITextViewDelegate.textViewDidChangeSelection(_:))) else {
            if let frozenText = frozenPrefix where textView == placeholderView && !NSEqualRanges(textView.selectedRange, NSMakeRange(frozenText.characters.count, 0)) {
                    moveCursorAfterFrozenTextIfPossible()
            } else if textView == self {
                moveCursorAfterFrozenTextIfPossibleInMainTextView()
            }
            return
        }
        
        if textView == self {
            moveCursorAfterFrozenTextIfPossibleInMainTextView()
        }
        
        externalTextViewDelegate!.textViewDidChangeSelection!(textView)
    }
    
    public func textView(textView: UITextView, shouldInteractWithURL URL: NSURL, inRange characterRange: NSRange) -> Bool {
        guard isExternalTextViewDelegateRespondsToSelector(#selector(UITextViewDelegate.textView(_:shouldInteractWithURL:inRange:))) else { return true }
        return externalTextViewDelegate!.textView!(textView, shouldInteractWithURL: URL, inRange: characterRange)
    }
    
    public func textView(textView: UITextView, shouldInteractWithTextAttachment textAttachment: NSTextAttachment, inRange characterRange: NSRange) -> Bool {
        guard isExternalTextViewDelegateRespondsToSelector(#selector(UITextViewDelegate.textView(_:shouldInteractWithTextAttachment:inRange:))) else { return true }
        return externalTextViewDelegate!.textView!(textView, shouldInteractWithTextAttachment: textAttachment, inRange: characterRange)
    }
    
}
