//
//  ViewController.swift
//  Image Uploader
//
//  Created by Ozan Mirza on 3/9/19.
//  Copyright © 2019 Ozan Mirza. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet weak var filesView: ScrollView!
    @IBOutlet weak var newFileView: DropView!
    @IBOutlet weak var itemName: NSTextField!
    @IBOutlet weak var itemDescription: NSTextField!
    
    var image: NSImage!
    var fileName: String!
    var fileDescription: String!
    var selectedItem: ImageFile? {
        didSet {
            itemName.stringValue = selectedItem?.name ?? ""
            itemDescription.stringValue = selectedItem?.description ?? ""
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        newFileView.translatesAutoresizingMaskIntoConstraints = false
        newFileView.applyGradient(with: [
            NSColor(hex: "#141E30", alpha: 1.0),
            NSColor(hex: "#243B55", alpha: 1.0),
        ])
        newFileView.applyCornerRadius(to: 50)
        newFileView.layer?.borderWidth = 10
        newFileView.layer?.borderColor = NSColor.gray.withSystemEffect(.disabled).cgColor
        newFileView.delegate = self
        
        filesView.delegate = self
        nextResponder = filesView
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        filesView.loadImageFiles()
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        guard let destination = segue.destinationController as? CameraViewController else {
            guard let destination = segue.destinationController as? URLGeneratorViewController else {
                guard let destination = segue.destinationController as? AddNewItemViewController else {
                    return
                }
                destination.delegate = self
                return
            }
            destination.delegate = self
            return
        }
        destination.delegate = self
    }
    
    @IBAction func openFileBrowser(_ sender: Any) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canCreateDirectories = false
        panel.canChooseFiles = true
        panel.allowedFileTypes = newFileView.expectedExt
        panel.beginSheetModal(for: view.window!) {
            if $0 == .OK {
                self.fileName = "\(panel.urls[0].lastPathComponent).\(panel.urls[0].pathExtension)"
                self.image = NSImage(contentsOf: panel.urls[0])
                self.performSegue(withIdentifier: "presentInformationController", sender: self)
            }
        }
    }
    
    @IBAction func shareFile(_ sender: Any) {
        guard let selectedItem = selectedItem else { return }
        let sharingPicker = NSSharingServicePicker(items: [
            selectedItem.image,
            selectedItem.name,
            selectedItem.description,
            selectedItem.link
        ])
        sharingPicker.show(relativeTo: .zero, of: sender as! NSButton, preferredEdge: .maxY)
    }
    
    @IBAction func downloadFile(_ sender: Any) {
        guard let selectedItem = selectedItem else { return }
    
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.canChooseFiles = false
        panel.beginSheetModal(for: view.window!) {
            if $0 == .OK {
                guard let destination = panel.urls.first?.appendingPathComponent(String(selectedItem.name.prefix(selectedItem.name.count - 4))) else { return }
                let operation = selectedItem.image.write(to: destination, atomically: true, usingType: .png)
                if operation.saved {
                    NSWorkspace.shared.activateFileViewerSelecting([operation.destination!])
                }
            }
        }
    }
    
    @IBAction func copyFileLink(_ sender: Any) {
        guard let selectedItem = selectedItem else { return }
        addToClipboard(selectedItem.link.absoluteString)
        NSAlert.informative("URL Copied")
    }
    
    @IBAction func deleteItem(_ sender: Any) {
        guard selectedItem != nil else { return }
        NSAlert.warning("Are you sure?", "The link for the file will still be active.") { [self] in
            if $0 == .init(1000) {
                UserImages.standard.remove(at: Int(filesView.currentPage - 1))
                filesView.loadImageFiles()
            }
        }
    }
    
    @IBAction func manuallyScrollUp(_ sender: Any) {
        filesView.scrollPageUp(sender)
    }
    
    @IBAction func manuallyScrollDown(_ sender: Any) {
        filesView.scrollPageDown(sender)
    }
}

extension ViewController: DropViewDelegate {
    func fileWasCopied(_ dropView: DropView) {
        fileName = dropView.filePath
        image = NSImage(contentsOfFile: dropView.filePath!)
        performSegue(withIdentifier: "presentInformationController", sender: self)
    }
}

extension ViewController: AddNewItemControllerDelegate {
    func getImage() -> NSImage {
        return image
    }
    
    func getFileName() -> String {
        return fileName
    }
    
    func finishedWriting(with fileName: String, and fileDescription: String) {
        self.fileName = fileName
        self.fileDescription = fileDescription
        performSegue(withIdentifier: "presentURLCreationController", sender: self)
    }
}

extension ViewController: URLGeneratorViewControllerDelegate {
    func linkWasSelected(_ link: URL) {
        UserImages.standard.add(fileName, fileDescription, image.png!, link)
        filesView.loadImageFiles()
        filesView.scrollToEndOfDocument(nil)
        
        guard let mwc = view.window?.windowController as? MainWindow else { return }
        mwc.scroller.reloadData()
    }
    
    func imageToUpload() -> NSImage {
        return image
    }
}

extension ViewController: CameraViewControllerDelegate {
    func cameraViewControllerDidFinish(_ cameraViewController: CameraViewController) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        fileName = "Camera Picture: \(formatter.string(from: Date()))"
        image = cameraViewController.snappedImage!
        
        dismiss(cameraViewController)
        performSegue(withIdentifier: "presentInformationController", sender: self)
    }
}

extension ViewController: ScrollViewDelegate {
    func updatedScroll(_ visibleItem: ImageFile?) {
        self.selectedItem = visibleItem
    }
}
