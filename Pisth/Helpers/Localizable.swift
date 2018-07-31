// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import Foundation

public class Static {
    private init() {}
}

/// A class containing localizable strings used in code.
class Localizable: Static {
    
    // MARK: - Basic
    
    /// Ok
    static let ok = NSLocalizedString("ok", comment: "Ok")
    
    /// Yes
    static let yes = NSLocalizedString("yes", comment: "Yes")
    
    /// No
    static let no = NSLocalizedString("no", comment: "No")
    
    /// Cancel
    static let cancel = NSLocalizedString("cancel", comment: "Cancel")
    
    /// Loading
    static let loading = NSLocalizedString("loading", comment: "Loading")
    
    /// Copying
    static let copying = NSLocalizedString("copying", comment: "Copying")
    
    /// Uploading
    static let uploading = NSLocalizedString("uploading", comment: "Uploading")
    
    /// Create
    static let create = NSLocalizedString("create", comment: "Create")
    
    /// Connect
    static let connect = NSLocalizedString("connect", comment: "Connect")
    
    /// Title for the alert shown when there is an error saving the file.
    static let errorSavingFile = NSLocalizedString("errorSavingFile", comment: "Title for the alert shown when there is an error saving the file.")
    
    // MARK: - Other
    
    class ArrowsViewControllers: Static {
        
        /// Text displayed after disabling `ArrowsViewControllers`.
        static let helpTextScroll = NSLocalizedString("arrows.helpTextScroll", comment: "Text displayed after disabling `ArrowsViewControllers`.")
        
        /// Text displayed after enabling `ArrowsViewControllers`.
        static let helpTextArrows = NSLocalizedString("arrows.helpTextArrows", comment: "Text displayed after enabling `ArrowsViewControllers`.")
    }
    
    class Git: Static {
        
        /// Commits for <branch>
        ///
        /// - Parameters:
        ///     - branch: Name of the branch.
        ///
        /// - Returns: Commits for `branch`
        static func commits(for branch: String) -> String {
            return NSString(format: NSLocalizedString("git.commitsFor", comment: "Commits for <branch>") as NSString, branch) as String
        }
        
        /// Request a commit message to the user.
        static let commitMessage = NSLocalizedString("git.commitMessage", comment: "Request a commit message to the user.")
    }
    
    class TerminalViewController: Static {
        
        /// Disable selection mode.
        static let insertMode = NSLocalizedString("terminal.insertMode", comment: "Disable selection mode.")
        
        /// Request a commit message to the user.
        static let selectionMode = NSLocalizedString("terminal.selectionMode", comment: "Request a commit message to the user.")
        
        /// Paste text to the terminal.
        static let paste = NSLocalizedString("terminal.paste", comment: "Paste text to the terminal.")
        
        /// Title of an alert.
        static let selectAction = NSLocalizedString("terminal.selectAction", comment: "Title of an alert.")
        
        /// Key command description.
        static let sendUpArrow = NSLocalizedString("terminal.sendUpArrow", comment: "Key command description.")
        
        /// Key command description.
        static let sendDownArrow = NSLocalizedString("terminal.sendDownArrow", comment: "Key command description.")
        
        /// Key command description.
        static let sendLeftArrow = NSLocalizedString("terminal.sendLeftArrow", comment: "Key command description.")
        
        /// Key command description.
        static let sendRightArrow = NSLocalizedString("terminal.sendRightArrow", comment: "Key command description.")
        
        /// Key command description.
        static let sendEsc = NSLocalizedString("terminal.sendEscKey", comment: "Key command description")
        
        /// Key command description.
        ///
        /// - Parameters:
        ///     - key: Ctrl key to send.
        ///
        /// - Returns: Send ^`key`
        static func sendCtrl(_ key: String) -> String {
            return NSString(format: NSLocalizedString("terminal.sendCtrlKey", comment: "Key command description.") as NSString, key) as String
        }
        
        /// Title of function keys popover.
        static let functionKeys = NSLocalizedString("terminal.functionKey", comment: "Title of function keys popover.")
        
        /// Text printed after a connection error.
        static let errorConnecting = NSLocalizedString("terminal.errorConnecting", comment: "Text printed after a connection error.")
        
        /// Text printed after an authentication error.
        static let errorAuthenticating = NSLocalizedString("terminal.errorAuthenticating", comment: "Text printed after an authentication error.")
        
        /// Authenticate to send user's password.
        static func authenticateToSendPassword(of user: String) -> String {
        
            return NSString(format: NSLocalizedString("terminal.authenticateToSendPasswordFor", comment: "Authenticate to send user's password.") as NSString, user) as String
        }
        
        /// Ask for accepting invitation from peer.
        ///
        /// - Parameters:
        ///     - peer: Peer sending the invitation.
        ///
        /// - Returns: Accept invitation from `peer`?
        static func acceptInvitation(from peer: String) -> String {
            return NSString(format: NSLocalizedString("terminal.acceptInvitation", comment: "Ask for accepting invitation from peer.") as NSString, peer) as String
        }
        
        /// Ask for accepting invitation from peer.
        ///
        /// - Parameters:
        ///     - peer: Peer sending the invitation.
        ///
        /// - Returns: `peer` wants to see the terminal.
        static func peerWantsToSeeTheTerminal(_ peer: String) -> String {
            return NSString(format: NSLocalizedString("terminal.peerWantsToSeeTheTerminal", comment: "Ask for accepting invitation from peer.") as NSString, peer) as String
        }
        
        /// Accept invitation from peer.
        static let accept = NSLocalizedString("terminal.accept", comment: "Accept invitation from peer.")
        
        /// Decline invitation from peer.
        static let decline = NSLocalizedString("terminal.decline", comment: "Decline invitation from peer.")
    }
    
    class Settings: Static {
        
        /// Authenticate To Turn Off Authentication.
        static let authenticateToTurnOffAuthentication = NSLocalizedString("settings.authenticateToTurnOffAuthentication", comment: "Authenticate To Turn Off Authentication.")
        
        /// Cannot turn off authentication.
        static let cannotTurnOffAuthentication = NSLocalizedString("settings.cannotTurnOffAuthentication", comment: "Cannot turn off authentication.")
        
        /// Use Face ID.
        static let useFaceID = NSLocalizedString("settings.useFaceID", comment: "Use Face ID.")
        
        /// Use Touch ID.
        static let useTouchID = NSLocalizedString("settings.useTouchID", comment: "Use Touch ID")
    }
    
    class EditTextViewController: Static {
        
        /// Title for the alert shown when there is an error reading the file."
        static let errorOpeningFile = NSLocalizedString("editor.errorOpeningFile", comment: "Title for the alert shown when there is an error reading the file.")
        
        /// Ask for saving changes. Title of the alert.
        static let saveChangesTitle = NSLocalizedString("editor.saveChangesTitle", comment: "Ask for saving changes. Title of the alert.")
        
        /// Ask for saving changes. Message of the alert.
        static let saveChangesMessage = NSLocalizedString("editor.saveChangesMessage", comment: "Ask for saving changes. Message of the alert.")
        
        /// Don't save.
        static let dontSave = NSLocalizedString("editor.dontSave", comment: "Don't save.")
        
        /// Save file.
        static let save = NSLocalizedString("editor.save", comment: "Save file.")
        
        /// Ask for selecting a language for syntax highlighting.
        static let selectALanguage = NSLocalizedString("editor.selectLanguage", comment: "Ask for selecting a language for syntax highlighting.")
        
        /// No language selected.
        static let none = NSLocalizedString("editor.none", comment: "No language selected.")
        
        /// Use default language.
        static let `default` = NSLocalizedString("editor.default", comment: "Use default language")
        
        /// Ask for selecting a theme for syntax highlighting.
        static let selectATheme = NSLocalizedString("editor.selectTheme", comment: "Ask for selecting a theme for syntax highlighting.")
    }
    
    class Browsers: Static {
        
        /// Create a folder.
        static let createFolder = NSLocalizedString("browsers.createFolder", comment: "Create a folder.")
        
        /// Ask the user for typing the new folder's name.
        static let chooseNewFolderName = NSLocalizedString("browsers.chooseNewFolderName", comment: "Ask the user for typing the new folder's name.")
        
        /// Folder name placeholder.
        static let folderName = NSLocalizedString("browsers.folderName", comment: "Folder name placeholder.")
        
        /// Title of the alert shown when there was an error creating a file.
        static let errorCreatingFile = NSLocalizedString("browsers.errorCreatingFile", comment: "Title of the alert shown when there was an error creating a file.")
        
        /// Title of the alert shown when there was an error creating a directory.
        static let errorCreatingDirectory = NSLocalizedString("browsers.errorCreatingDirectory", comment: "Title of the alert shown when there was an error creating a directory.")
        
        /// Title of an alert shown when a file couldn't be moved.
        static let errorMovingFile = NSLocalizedString("browsers.errorMovingFile", comment: "Title of an alert shown when a file couldn't be moved.")
        
        /// Message of the alert shown when a file couldn't be moved or copied because the pasteboard is empty.
        static let noFileInPasteboard = NSLocalizedString("browsers.noFileInPasteboard", comment: "Message of the alert shown when a file couldn't be moved or copied because the pasteboard is empty.")
        
        /// Title of an alert shown when a file couldn't be copied.
        static let errorCopyingFile = NSLocalizedString("browsers.errorCopyingFile", comment: "Title of an alert shown when a file couldn't be copied.")
        
        /// Import file.
        static let `import` = NSLocalizedString("browsers.import", comment: "Import file.")
        
        /// Title of the alert shown for creating a file.
        static let createTitle = NSLocalizedString("browsers.createTitle", comment: "Title of the alert shown for creating a file.")
        
        /// Message of the alert shown for creating a file.
        static let createMessage = NSLocalizedString("browsers.createMessage", comment: "Message of the alert shown for creating a file.")
        
        /// Title of the alert shown when a directory couldn't be opened.
        static let errorOpeningDirectory = NSLocalizedString("browsers.errorOpeningDirectory", comment: "Title of the alert shown when a directory couldn't be opened.")
        
        /// Ask where a file should be copied.
        static let selectDirectoryWhereCopyFile = NSLocalizedString("browsers.selectDirectoryWhereCopyFile", comment: "Ask where a file should be copied.")
        
        /// Ask where a file should be moved.
        static let selectDirectoryWhereMoveFile = NSLocalizedString("browsers.selectDirectoryWhereMoveFile", comment: "Ask where a file should be moved.")
        
        /// Copy file in selected directory.
        static let copyHere = NSLocalizedString("browsers.copyHere", comment: "Copy file in selected directory.")
        
        /// Move file in selected directory.
        static let moveHere = NSLocalizedString("browsers.moveHere", comment: "Move file in selected directory.")
        
        /// Title of the alert shown when a file couldn't be imported.
        static let errorImporting = NSLocalizedString("browsers.errorImporting", comment: "Title of the alert shown when a file couldn't be imported.")
    }
    
    class LocalDirectoryCollectionViewController: Static {
        
        /// Create a plugin for the terminal.
        static let createTerminalPlugin = NSLocalizedString("local.createTerminalPlugin", comment: "Create a plugin for the terminal.")
        
        /// Title of the alert for creating a terminal plugin.
        static let createPluginTitle = NSLocalizedString("local.createPluginTitle", comment: "Title of the alert for creating a terminal plugin.")
        
        /// Message of the alert for creating a terminal plugin.
        static let createPluginMessage = NSLocalizedString("local.createPluginMessage", comment: "Message of the alert for creating a terminal plugin.")
        
        /// Placeholder for the new plugin name.
        static let createPluginPlaceholder = NSLocalizedString("local.createPluginPlaceholder", comment: "Placeholder for the new plugin name.")
        
        /// Title of the alert shown when there was an error creating a plugin.
        static let errorCreatingPluginTitle = NSLocalizedString("local.errorCreatingPluginTitle", comment: "Title of the alert shown when there was an error creating a plugin.")
        
        /// Message of the alert shown when there was an error creating a plugin.
        static let errorCreatingPluginMessage = NSLocalizedString("local.errorCreatingPluginMessage", comment: "Message of the alert shown when there was an error creating a plugin.")
        
        /// The tilte of an alert shown when an HTML file will be opened to ask how to open it.
        static let openFileTitle = NSLocalizedString("local.openFileTitle", comment: "The tilte of an alert shown when an HTML file will be opened to ask how to open it.")
        
        /// The message of an alert shown when an HTML file will be opened to ask how to open it.
        static let openFileMessage = NSLocalizedString("local.openFileMessage", comment: "The message of an alert shown when an HTML file will be opened to ask how to open it.")
        
        /// Edit the code of an HTML file.
        static let editHTML = NSLocalizedString("local.editHTML", comment: "Edit the code of an HTML file.")
        
        /// View HTML page.
        static let viewHTML = NSLocalizedString("local.viewHTML", comment: "View HTML page.")
    }
    
    class DirectoryCollectionViewController: Static {
        
        /// Error shown when the SFTP session couldn't read a remote item.
        static let checkForPermssions = NSLocalizedString("dir.checkForPermissions", comment: "Error shown when the SFTP session couldn't read a remote item.")
        
        /// Title of the alert shown when the session couldn't be opened.
        static let errorOpeningSessionTitle = NSLocalizedString("dir.errorOpeningSessionTitle", comment: "Title of the alert shown when the session couldn't be opened.")
        
        /// Message of the alert shown when the client couldn't connect to the server.
        static let errorConnecting = NSLocalizedString("dir.errorConnecting", comment: "Message of the alert shown when the client couldn't connect to the server.")
        
        /// Title of the alert shown when the session was closed.
        static let sessionClosedTitle = NSLocalizedString("dir.sessionClosedTitle", comment: "Title of the alert shown when the session was closed.")
        
        /// Message of the alert shown when the session was closed.
        static let sessionClosedMessage = NSLocalizedString("dir.sessionClosedMessage", comment: "Message of the alert shown when the session was closed.")
        
        /// Message of the alert shown when the client couldn't connect to the server.
        static let errorAuthenticating = NSLocalizedString("dir.errorAuthenticating", comment: "Message of the alert shown when the client couldn't login to the server.")
        
        /// Title of the alert shown when a file couldn't be uploaded.
        static let errorUploadingTitle = NSLocalizedString("dir.errorUploadingTitle", comment: "Title of the alert shown when a file couldn't be uploaded.")
        
        /// Message of the alert shown when a file couldn't be uploaded.
        static let errorUploadingMessage = NSLocalizedString("dir.errorUploadingMessage", comment: "Message of the alert shown when a file couldn't be uploaded.")
        
        /// Title of the alert shown when the data of a local file couldn't be read.
        static let errorReadingFile = NSLocalizedString("dir.errorReadingFile", comment: "Title of the alert shown when the data of a local file couldn't be read.")
        
        /// Message of the alert asking for sending a file to the server. Do you want to send <File> to <Directory>?
        ///
        /// - Parameters:
        ///     - file: File that the user will send.
        ///     - dir: Destination directory.
        ///
        /// - Returns: Do you want to send `file` to `dir`?
        static func send(_ file: String, to dir: String) -> String {
            return NSString(format: NSLocalizedString("dir.sendFile", comment: "Message of the alert asking for sending a file to the server. Do you want to send <File> to <Directory>?") as NSString, file, dir) as String
        }
        
        /// Import file from the Pisth sandbox.
        static let importFromPisth = NSLocalizedString("dir.importFromPisth", comment: "Import file from the Pisth sandbox.")
        
        /// Body of the notification sent when a file was downloaded.
        static let downloadFinished = NSLocalizedString("dir.downloadFinished", comment: "Body of the notification sent when a file was downloaded.")
        
        /// Downloading...
        static let downloading = NSLocalizedString("dir.downloading", comment: "Downloading...")
        
        /// Title of the alert shown after a download error.
        static let errorDownloading = NSLocalizedString("dir.errorDownloading", comment: "Title of the alert shown after a download error.")
        
        /// Title of the alert for asking the user for uploading files.
        ///
        /// - Parameters:
        ///     - filesCount: Count of files to be uploaded.
        ///
        /// - Returns: Upload `fileCount` files?
        static func uploadTitle(for filesCount: Int) -> String {
            return NSString(format: NSLocalizedString("dir.uploadFilesTitle", comment: "Title of the alert for asking the user for uploading files. Upload <Files count> files?") as NSString, filesCount) as String
        }
        
        /// Message of the alert for asking the user for uploading files.
        ///
        /// - Parameters:
        ///     - filesCount: Count of files to be uploaded.
        ///     - destination: The directory where the files will be uploaed.
        ///
        /// - Returns: Do you want to upload `filesCount` files to `Destination`?
        static func uploadMessage(for filesCount: Int, destination: String) -> String {
            return NSString(format: NSLocalizedString("dir.uploadFilesMessage", comment: "Message of the alert for asking the user for uploading files. Do you want to upload <Files count> files to <Destination>?") as NSString, filesCount, destination) as String
        }
        
        /// Message of the alert shown when a file couldn't be uploaded.
        ///
        /// - Parameters:
        ///     - file: File that should be uploaded.
        ///     - destination: Directory where the file should be uploaded.
        ///
        /// - Returns: Error uploading `file` to `destination`.
        static func errorUploading(file: String, to destination: String) -> String {
            return NSString(format: NSLocalizedString("dir.errorUploadingFileToDestination", comment: "Message of the alert shown when a file couldn't be uploaded. Error uploading <File> to <Destination>.") as NSString, file, destination) as String
        }
    }
    
    class BookmarksTableViewController: Static {
        
        /// Title of the alert shown when a session that is already active was clicked.
        static let sessionAlreadyActiveTitle = NSLocalizedString("bookmaks.sessionAlreadyActiveTitle", comment: "Title of the alert shown when a session that is already active was clicked.")
        
        /// Message of the alert shown when a session that is already active was clicked.
        static let sessionAlreadyActiveMessage = NSLocalizedString("bookmaks.sessionAlreadyActiveMessage", comment: "Message of the alert shown when a session that is already active was clicked.")
        
        /// Resume the session.
        static let resume = NSLocalizedString("bookmarks.resume", comment: "Resume the session.")
        
        /// Restart the session.
        static let restart = NSLocalizedString("bookmarks.restart", comment: "Restart the session.")
        
        /// Bookmarks title.
        static let bookmarksTitle = NSLocalizedString("bookmarks.title", comment: "Bookmarks title.")
        
        /// Connections title header.
        static let connectionsTitle = NSLocalizedString("bookmarks.connections", comment: "Connections title header.")
        
        /// Devices title header.
        static let devicesTitle = NSLocalizedString("bookmarks.devices", comment: "Devices title header.")
        
        /// Title of the alert shown while connecting to a session.
        static let connecting = NSLocalizedString("bookmarks.connecting", comment: "Title of the alert shown while connecting to a session.")
        
        /// Title of the alert for asking the user for the password.
        static let enterPasswordTitle = NSLocalizedString("bookmarks.enterPasswordTitle", comment: "Title of the alert for asking the user for the password.")
        
        /// Message of the alert for asking the user for the password.
        ///
        /// - Parameters:
        ///     - user: User to connect to.
        ///
        /// - Returns: Enter password for user `user`.
        static func enterPasswordMessage(for user: String) -> String {
            return NSString(format: NSLocalizedString("bookmarks.enterPasswordMessage", comment: "Message of the alert for asking the user for the password. Enter password for user <User>.") as NSString, user) as String
        }
        
        /// Authenticate with biometry to connect to the connection.
        static let authenticateToConnect = NSLocalizedString("bookmarks.authenticateToConnect", comment: "Authenticate with biometry to connect to the connection.")
        
        /// Enter password if biometry auth failed.
        static let enterPassword = NSLocalizedString("bookmarks.enterPassword", comment: "Enter password if biometry auth failed.")
    }
    
    class FileCollectionViewCell: Static {
        
        /// Title of the alert shown while removing file.
        static let removing = NSLocalizedString("cell.removing", comment: "Title of the alert shown while removing file.")
        
        /// The title of the alert shown when a directory couldn't be removed.
        static let errorRemovingDirectory = NSLocalizedString("cell.errorRemovingDirectory", comment: "The title of the alert shown when a directory couldn't be removed.")
        
        /// The title of the alert shown when a file couldn't be removed.
        static let errorRemovingFile = NSLocalizedString("cell.errorFile", comment: "The title of the alert shown when a file couldn't be removed.")
        
        /// The title of the alert for rename a file.
        static let renameFileTitle = NSLocalizedString("cell.renameFileTitle", comment: "The title of the alert for rename a file")
        
        /// The message of the alert for rename a file.
        ///
        /// - Parameters:
        ///     - file: File to rename.
        ///
        /// - Returns: Write new name for `file`.
        static func rename(file: String) -> String {
            return NSString(format: NSLocalizedString("cell.renameFileMessage", comment: "The mesage of the alert for rename a file. Write new name for <fileToRename.filename>.") as NSString, file) as String
        }
        
        /// New file name placeholder.
        static let newFileName = NSLocalizedString("cell.newFileName", comment: "New file name placeholder.")
        
        /// Rename file.
        static let rename = NSLocalizedString("cell.rename", comment: "Rename file.")
        
        /// Title of the alert shown when a file couldn't be renamed.
        static let errorRenaming = NSLocalizedString("cell.errorRenaming", comment: "Title of the alert shown when a file couldn't be renamed.")
    }
    
    class UIMenuItem: Static {
        
        /// Delete
        static let delete = NSLocalizedString("menu.delete", comment: "Delete")
        
        /// Move
        static let move = NSLocalizedString("menu.move", comment: "Move")
        
        /// Rename
        static let rename = NSLocalizedString("menu.rename", comment: "Rename")
        
        /// Info
        static let info = NSLocalizedString("menu.info", comment: "Info")
        
        /// Share
        static let share = NSLocalizedString("menu.share", comment: "Share")
        
        /// Open in new panel
        static let openInNewPanel = NSLocalizedString("menu.openInNewPanel", comment: "Open in new panel")
        
        /// Selection mode
        static let selectionMode = NSLocalizedString("menu.selectionMode", comment: "Selection mode")
        
        /// Insert mode
        static let insertMode = NSLocalizedString("menu.insertMode", comment: "Insert mode")
        
        /// Paste
        static let paste = NSLocalizedString("cell.paste", comment: "Paste")
        
        /// Toggle top bar
        static let toggleTopBar = NSLocalizedString("cell.toggleTopBar", comment: "Toggle top bar")
        
        /// Paste selection
        static let pasteSelection = NSLocalizedString("cell.pasteSelection", comment: "Paste selection")
    }
    
    class AppDelegate: Static {
        
        /// Title for the alert shown for authenticating to the session opened by an URL.
        static let openSSHConnection = NSLocalizedString("delegate.openSSHConnection", comment: "Title for the alert shown for authenticating to the session opened by an URL.")
        
        /// Ask for the password.
        ///
        /// - Parameters:
        ///     - user: User of the connection.
        ///
        /// - Returns: Authenticate as `user` user.
        static func authenticate(as user: String) -> String{
            return NSString(format: NSLocalizedString("delegate.authenticateAsUser", comment: "Ask for the password. Authenticate as <User> user.") as NSString, user) as String
        }
        
        /// Username placeholder.
        static let usernamePlaceholder = NSLocalizedString("delegate.usernamePlaceholder", comment: "Username placeholder.")
        
        /// Password placeholder.
        static let passwordPlaceholder = NSLocalizedString("delegate.passwordPlaceholder", comment: "Password placeholder.")
        
        /// Open the session.
        static let connect = NSLocalizedString("delegate.connect", comment: "Open the session")
        
        /// Open the session and save it.
        static let connectAndRemember = NSLocalizedString("delegate.connectAndRemember", comment: "Open the session and save it")
        
        /// Title of the alert for importing a plugin.
        static let usePluginTitle = NSLocalizedString("delegate.usePluginTitle", comment: "Title of the alert for importing a plugin.")
        
        /// Message of the alert for importing a plugin.
        static let usePluginMessage = NSLocalizedString("delegate.usePluginMessage", comment: "Message of the alert for importing a plugin.")
        
        /// Use plugin.
        static let usePlugin = NSLocalizedString("delegate.usePlugin", comment: "Use plugin.")
        
        /// Select connection to upload file.
        static let selectConnectionToUploadFile = NSLocalizedString("delegate.selectConectionToUploadFile", comment: "Select connection to upload file.")
        
        /// Select connection to export file.
        static let selectConnectionToExportFile = NSLocalizedString("delegate.selectConectionToExportFile", comment: "Select connection to export file.")
        
        /// Select file to import.
        static let selectFiletoImport = NSLocalizedString("delegate.selectFileToImport", comment: "Select file to import.")
        
        /// Select directory to upload file.
        static let selectFolderWhereUploadFile = NSLocalizedString("delegate.selectFolderWhereUploadFile", comment: "Select directory to upload file.")
    }
    
    class FileInfoViewController: Static {
        
        /// Title of the View controller.
        static let title = NSLocalizedString("info.title", comment: "Title of the View controller.")
        
        /// Symbolic link.
        static let symLink = NSLocalizedString("info.symLink", comment: "Symbolic link.")
        
        /// Directory.
        static let directory = NSLocalizedString("info.directory", comment: "Directory.")
        
        /// Describe a file.
        ///
        /// - Parameters:
        ///     - pathExtension: Extension of the file.
        ///
        /// - Returns: `pathExtension` file
        static func file(withPathExtension pathExtension: String) -> String {
            return NSString(format: NSLocalizedString("info.fileWithExtension", comment: "Describe file.") as NSString, pathExtension) as String
        }
    }
    
    class ConnectionInformationViewController: Static {
        
        /// Change public key.
        static let changePublicKey = NSLocalizedString("connection.changePubKey", comment: "Change public key.")
        
        /// Change private key.
        static let changePrivateKey = NSLocalizedString("connection.changePrivKey", comment: "Change private key.")
        
        /// Import public key.
        static let importPublicKey = NSLocalizedString("connection.importPubKey", comment: "Import public key.")
        
        /// Import private key.
        static let importPrivateKey = NSLocalizedString("connection.importPrivKey", comment: "Import private key.")
        
        /// Passphrase for key placeholder.
        static let passphrase = NSLocalizedString("connection.passphrase", comment: "Passphrase for key placeholder")
    }
}
