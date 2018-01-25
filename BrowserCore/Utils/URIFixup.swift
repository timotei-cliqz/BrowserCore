/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class URIFixup {
    static func getURL(_ entry: String) -> URL? {
        let trimmed = entry.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard let escaped = trimmed.addingPercentEncoding(withAllowedCharacters: CharacterSet.URLAllowedCharacterSet()) else {
            return nil
        }
        
        // Then check if the URL includes a scheme. This will handle
        // all valid requests starting with "http://", "about:", etc.
        // However, we ensure that the scheme is one that is listed in
        // the official URI scheme list, so that other such search phrases
        // like "filetype:" are recognised as searches rather than URLs.
        if let url = punycodedURL(escaped), url.schemeIsValid {
            return url
        }
        
        // If there's no scheme, we're going to prepend "http://". First,
        // make sure there's at least one "." in the host. This means
        // we'll allow single-word searches (e.g., "foo") at the expense
        // of breaking single-word hosts without a scheme (e.g., "localhost").
        if trimmed.range(of: ".") == nil {
            return nil
        }
        
        if trimmed.range(of: " ") != nil {
            return nil
        }
        
        // If there is a ".", prepend "http://" and try again. Since this
        // is strictly an "http://" URL, we also require a host.
        if let url = punycodedURL("http://\(escaped)"), url.host != nil {
            return url
        }
        
        return nil
    }
    
    static func punycodedURL(_ string: String) -> URL? {
        let components = URLComponents(string: string)
        return components?.url
    }
}

extension CharacterSet {
    public static func URLAllowedCharacterSet() -> CharacterSet {
        return CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~:/?#[]@!$&'()*+,;=%")
    }
    
    public static func SearchTermsAllowedCharacterSet() -> CharacterSet {
        return CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789*-_.")
    }
}

// The list of permanent URI schemes has been taken from http://www.iana.org/assignments/uri-schemes/uri-schemes.xhtml
private let permanentURISchemes = ["aaa", "aaas", "about", "acap", "acct", "cap", "cid", "coap", "coaps", "crid", "data", "dav", "dict", "dns", "example", "file", "ftp", "geo", "go", "gopher", "h323", "http", "https", "iax", "icap", "im", "imap", "info", "ipp", "ipps", "iris", "iris.beep", "iris.lwz", "iris.xpc", "iris.xpcs", "jabber", "ldap", "mailto", "mid", "msrp", "msrps", "mtqp", "mupdate", "news", "nfs", "ni", "nih", "nntp", "opaquelocktoken", "pkcs11", "pop", "pres", "reload", "rtsp", "rtsps", "rtspu", "service", "session", "shttp", "sieve", "sip", "sips", "sms", "snmp", "soap.beep", "soap.beeps", "stun", "stuns", "tag", "tel", "telnet", "tftp", "thismessage", "tip", "tn3270", "turn", "turns", "tv", "urn", "vemmi", "vnc", "ws", "wss", "xcon", "xcon-userid", "xmlrpc.beep", "xmlrpc.beeps", "xmpp", "z39.50r", "z39.50s"]


extension URL {
    /**
     Returns whether the URL's scheme is one of those listed on the official list of URI schemes.
     This only accepts permanent schemes: historical and provisional schemes are not accepted.
     */
    public var schemeIsValid: Bool {
        guard let scheme = scheme else { return false }
        return permanentURISchemes.contains(scheme.lowercased())
    }
}
