import Foundation
import Oniguruma

/// Options for regex search operations
public struct SearchOptions: OptionSet {
    public let rawValue: OnigOptionType
    
    public init(rawValue: OnigOptionType) {
        self.rawValue = rawValue
    }
    
    /// Default options (none)
    public static let none = SearchOptions(rawValue: ONIG_OPTION_NONE)
    
    /// Do not regard the beginning of the string as the beginning of the line and string
    public static let notBeginOfLine = SearchOptions(rawValue: ONIG_OPTION_NOTBOL)
    
    /// Do not regard the end of the string as the end of a line and string
    public static let notEndOfLine = SearchOptions(rawValue: ONIG_OPTION_NOTEOL)
    
    /// Do not regard the beginning of the string as the beginning of a string (\A fails)
    public static let notBeginString = SearchOptions(rawValue: ONIG_OPTION_NOT_BEGIN_STRING)
    
    /// Do not regard the end as a string endpoint (\z, \Z fail)
    public static let notEndString = SearchOptions(rawValue: ONIG_OPTION_NOT_END_STRING)
    
    /// Do not regard the start position as start position of search (\G fails)
    public static let notBeginPosition = SearchOptions(rawValue: ONIG_OPTION_NOT_BEGIN_POSITION)
}