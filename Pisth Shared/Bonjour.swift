// The MIT License (MIT)

// Copyright (c) 2016 Ian Spence

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation

class Bonjour: NSObject, NetServiceBrowserDelegate {
    var timeout: TimeInterval = 1.0
    var serviceFoundClosure: (([NetService]) -> Void)!
    var domainFoundClosure: (([String]) -> Void)!

    // Source: https://developer.apple.com/library/mac/qa/qa1312/_index.html
    struct Services {
        // Used by Personal File Sharing in the Sharing preference panel starting in Mac OS X 10.2.
        // The Finder browses for AFP servers starting in Mac OS X 10.2.
        static let AppleTalk_Filing: String = "_afpovertcp._tcp."
        // The Finder browses for NFS servers starting in Mac OS X 10.2.
        static let Network_File_System: String = "_nfs._tcp."
        // The Finder browses for WebDAV servers but because of a bug (r. 3171023), double-clicking
        // a discovered server fails to connect.
        static let WebDAV_File_System: String = "_webdav._tcp."
        // Used by FTP Access in the Sharing preference panel starting in Mac OS X 10.2.2.
        // The Finder browses for FTP servers starting in Mac OS X 10.3.
        // The Terminal application also browses for FTP servers starting in Mac OS X 10.3.
        static let File_Transfer: String = "_ftp._tcp."
        // Used by Remote Login in the Sharing preference panel starting in Mac OS X 10.3.
        // The Terminal application browses for SSH servers starting in Mac OS X 10.3.
        static let Secure_Shell: String = "_ssh._tcp."
        // Used by Remote AppleEvents in the Sharing preference panel starting in Mac OS X 10.2.
        static let Remote_AppleEvents: String = "_eppc._tcp."
        // Used by Personal Web Sharing in the Sharing preference panel to advertise the User's
        // Sites folders starting in Mac OS X 10.2.4. Safari can be used to browse for web servers.
        static let Hypertext_Transfer: String = "_http._tcp."
        // If Telnet is enabled, xinetd will advertise it via Bonjour starting in Mac OS X 10.3.
        // The Terminal application browses for Telnet servers starting in Mac OS X 10.3.
        static let Remote_Login: String = "_telnet._tcp."
        // Print Center browses for LPR printers starting in Mac OS X 10.2.
        static let Line_Printer_Daemon: String = "_printer._tcp."
        // Print Center browses for IPP printers starting in Mac OS X 10.2.
        static let Internet_Printing: String = "_ipp._tcp."
        // Print Center browses for PDL Data Stream printers starting in Mac OS X 10.2.
        static let PDL_Data_Stream: String = "_pdl-datastream._tcp."
        // Used by the AirPort Extreme Base Station to share USB printers. Printer Setup Utility
        // browses for AirPort Extreme shared USB printers which use the Remote I/O USB Printer
        // Protocol starting in Mac OS X 10.3.
        static let Remote_IO_USB_Printer: String = "_riousbprint._tcp."
        // Also known as iTunes Music Sharing. iTunes advertises and browses for DAAP servers
        // starting in iTunes 4.0.
        static let Digital_Audio_Access: String = "_daap._tcp."
        // Also known as iPhoto Photo Sharing. iPhoto advertises and browses for DPAP servers
        // starting in iPhoto 4.0.
        static let Digital_Photo_Access: String = "_dpap._tcp."
        // Used by iChat 1.0 which shipped with Mac OS X 10.2. This service is now deprecated with
        // the introduction of the "presence" service in iChat AV. See below.
        static let iChat_Instant_Messaging_Deprecated: String = "_ichat._tcp."
        // Used by iChat AV which shipped with Mac OS X 10.3.
        static let iChat_Instant_Messaging: String = "_presence._tcp."
        // Used by the Image Capture application to share cameras in Mac OS X 10.3.
        static let Image_Capture_Sharing: String = "_ica-networking._tcp."
        // Used by the AirPort Admin Utility starting in Mac OS X 10.2 in order to locate and
        // configure the AirPort Base Station (Dual Ethernet) and the AirPort Extreme Base Station.
        static let AirPort_Base_Station: String = "_airport._tcp."
        // Used by the Xserve RAID Admin Utility to locate and configure Xserve RAID hardware.
        static let Xserve_RAID: String = "_xserveraid._tcp."
        // Used by Xcode in its Distributed Builds feature.
        static let Distributed_Compiler: String = "_distcc._tcp."
        // Used by Open Directory Password Server starting in Mac OS X Server 10.3.
        static let Apple_Password_Server: String = "_apple-sasl._tcp."
        // Open Directory advertises this service starting in Mac OS X 10.2. Workgroup Manager
        // browses for this service starting in Mac OS X Server 10.2.
        static let Workgroup_Manager: String = "_workstation._tcp."
        // Mac OS X Server machines advertise this service starting in Mac OS X 10.3. Server
        // Admin browses for this service starting in Mac OS X Server 10.3.
        static let Server_Admin: String = "_servermgr._tcp."
        // Also known as AirTunes. The AirPort Express Base Station advertises this service.
        // iTunes browses for this service starting in iTunes 4.6.
        static let Remote_Audio_Output: String = "_raop._tcp."
        // Used by the Xcode Service Service in the Apple Server App
        static let Xcode_Server: String = "_xcs2p._tcp."
    }
    static let LocalDomain: String = "local."

    let serviceBrowser: NetServiceBrowser = NetServiceBrowser()
    var services = [NetService]()
    var domains = [String]()
    var isSearching: Bool = false
    var serviceTimeout: Timer = Timer()
    var domainTimeout: Timer = Timer()

    /// Find all servies matching the given identifer in the given domain
    ///
    /// Calls servicesFound: with any services found
    /// If no services were found, servicesFound: is called with an empty array
    ///
    /// **Please Note:** Only one search can run at a time.
    ///
    /// - parameters:
    ///   - identifier: The service identifier. You may use Bonjour.Services for common services
    ///   - domain: The domain name for the service.  You may use Bonjour.LocalDomain
    /// - returns: True if the search was started, false if a search is already running
    func findService(_ identifier: String, domain: String, found: @escaping ([NetService]) -> Void) -> Bool {
        if !isSearching {
            serviceBrowser.delegate = self
            serviceTimeout = Timer.scheduledTimer(
                timeInterval: self.timeout,
                target: self,
                selector: #selector(Bonjour.noServicesFound),
                userInfo: nil,
                repeats: false)
            serviceBrowser.searchForServices(ofType: identifier, inDomain: domain)
            serviceFoundClosure = found
            isSearching = true
            return true
        }
        return false
    }

    /// Find all of the browsable domains
    ///
    /// Calls domainsFound: with any domains found
    /// If no domains were found, domainsFound: is called with an empty array
    ///
    /// **Please Note:** Only one search can run at a time.
    ///
    /// - returns: True if the search was started, false if a search is already running
    func findDomains(_ found: @escaping ([String]) -> Void) -> Bool {
        if !isSearching {
            serviceBrowser.delegate = self
            domainTimeout = Timer.scheduledTimer(
                timeInterval: self.timeout,
                target: self,
                selector: #selector(Bonjour.noDomainsFound),
                userInfo: nil,
                repeats: false)
            serviceBrowser.searchForBrowsableDomains()
            domainFoundClosure = found
            isSearching = true
            return true
        }
        return false
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService,
                           moreComing: Bool) {
        serviceTimeout.invalidate()
        services.append(service)
        if !moreComing {
            serviceFoundClosure(services)
            serviceBrowser.stop()
            isSearching = false
        }
    }

    @objc func noServicesFound() {
        serviceFoundClosure([])
        serviceBrowser.stop()
        isSearching = false
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didFindDomain domainString: String,
                           moreComing: Bool) {
        domainTimeout.invalidate()
        domains.append(domainString)
        if !moreComing {
            domainFoundClosure(domains)
            serviceBrowser.stop()
            isSearching = false
        }
    }

    @objc func noDomainsFound() {
        domainFoundClosure([])
        serviceBrowser.stop()
        isSearching = false
    }
}
