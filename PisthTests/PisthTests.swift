// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import XCTest

import Pisth_Shared
import NMSSH
@testable import Pisth

class PisthTests: XCTestCase, NMSSHChannelDelegate {
    
    /// Connects to the test connection.
    ///
    /// - Returns: The opened session.
    func connect() throws -> NMSSHSession {
        let session = NMSSHSession.connect(toHost: TestingConnection.host, withUsername: TestingConnection.username)
        
        guard session != nil, session!.isConnected else {
            throw NSError(domain: "pisth_tests", code: 1, userInfo: [NSLocalizedDescriptionKey : "Unable to connect."])
        }
        
        guard session!.authenticate(byPassword: TestingConnection.password) else {
            throw NSError(domain: "pisth_tests", code: 2, userInfo: [NSLocalizedDescriptionKey : "Unable to authenticate."])
        }
        
        return session!
    }
    
    // MARK: - Shell
    
    /// The expectation used by the shell test for waiting for last command output.
    var shellExpectation: XCTestExpectation?
    
    /// The console caught by the shell test.
    var console = ""
    
    // MARK: - Test case
    
    override func setUp() {
        continueAfterFailure = false
    }
    
    // MARK: - Channel delegate
    
    func channel(_ channel: NMSSHChannel!, didReadData message: String!) {
        print(message ?? "", terminator: "")
        console += message
        
        if console.contains("FINISHED") {
            shellExpectation?.fulfill()
        }
    }
    
    // MARK: - Tests
    
    func testSSH() {
        
        do {
            let session = try connect()
            try session.channel.execute("whoami")
            try session.channel.execute("ls /")
            session.disconnect()
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testSFTP() {
        
        do {
            let session = try connect()
            XCTAssertTrue(session.sftp.connect(), "Unable to open SFTP.")
            
            let dirContents = session.sftp.contentsOfDirectory(atPath: "/") as? [NMSFTPFile]
            XCTAssertTrue(dirContents != nil, "Unable to see directory contents.")
            
            let testPath = "/home/pisthtest/hello.test"
            let localData = "Hello World!".data(using: .utf8) ?? Data()
            XCTAssertTrue(session.sftp.writeContents(localData, toFileAtPath: testPath), "Unable to create file.")
            
            let data = session.sftp.contents(atPath: testPath)
            XCTAssertTrue(data != nil, "Unable to download file.")
            XCTAssertTrue(data == localData, "Data doesn't seems to have been transfered properly.")
            
            XCTAssertTrue(session.sftp.removeFile(atPath: testPath), "Unable to remove file.")
            
            session.disconnect()
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testShell() {
        
        shellExpectation = expectation(description: "Run shell")
        
        var session: NMSSHSession!
        do {
            session = try connect()
            session.channel.delegate = self
            session.channel.requestPty = true
            session.channel.ptyTerminalType = .xterm
            try session.channel.startShell()
            
            try session.channel.write("nano\n")
            sleep(1)
            try session.channel.write(Keys.ctrlX)
            sleep(1)
            try session.channel.write("vim\n")
            sleep(1)
            try session.channel.write(Keys.esc)
            sleep(1)
            try session.channel.write(":q\n")
            sleep(1)
            try session.channel.write("echo 'FINISHED'")
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        waitForExpectations(timeout: 20, handler: { _ in
            session.channel.closeShell()
            session.disconnect()
        })
    }
}
