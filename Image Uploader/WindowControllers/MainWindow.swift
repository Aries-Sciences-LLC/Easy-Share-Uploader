//
//  MainWindow.swift
//  Image Uploader
//
//  Created by Ozan Mirza on 3/9/19.
//  Copyright © 2019 Ozan Mirza. All rights reserved.
//

import Cocoa

var loadCount : Int = 0

class MainWindow: NSWindowController {
    
    @IBOutlet weak var scroller: NSScrubber!
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        
        //        [WAYTheDarkSide welcomeApplicationWithBlock:^{
        //            [weakSelf.window setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameVibrantDark]];
        //            [weakSelf.contentView setMaterial:NSVisualEffectMaterialDark];
        //            [self.label setStringValue:@"Dark!"];
        //        } immediately:YES];
        
        let toolbar = NSToolbar()
        toolbar.showsBaselineSeparator = false
        window?.toolbar = toolbar
    }
    
    override func keyDown(with event: NSEvent) {
        guard let vc = contentViewController as? ViewController else { return }
        vc.filesView.keyDown(with: event)
    }
    
    @IBAction func create(_ sender: Any) {
        guard let cvc = window?.contentViewController as? ViewController else { return }
        cvc.openFileBrowser(sender)
    }
    
    @IBAction func camera(_ sender: Any) {
        guard let cvc = window?.contentViewController as? ViewController else { return }
        cvc.performSegue(withIdentifier: "displayCameraController", sender: cvc)
    }
    
    @IBAction func share(_ sender: Any) {
        guard let cvc = window?.contentViewController as? ViewController else { return }
        cvc.shareFile(sender)
    }
    
    @IBAction func download(_ sender: Any) {
        guard let cvc = window?.contentViewController as? ViewController else { return }
        cvc.downloadFile(sender)
    }
    
    @IBAction func copy(_ sender: Any) {
        guard let cvc = window?.contentViewController as? ViewController else { return }
        cvc.copyFileLink(sender)
    }
    
    @IBAction func trash(_ sender: Any) {
        guard let cvc = window?.contentViewController as? ViewController else { return }
        cvc.deleteItem(sender)
    }
    
//    override func makeTouchBar() -> NSTouchBar? {
//        guard let cvc = window?.contentViewController as? ViewController else {
//            return touchBar
//        }
//
//        switch cvc.presentingViewController {
//        case is CameraViewController:
//            let tb = NSTouchBar()
//            tb.
//        case is AddNewItemViewController:
//            break
//        case is URLGeneratorViewController:
//            break
//        case nil:
//            return touchBar
//        case .some(_):
//            return touchBar
//        }
//    }
}

extension MainWindow: NSScrubberDataSource {
    func numberOfItems(for scrubber: NSScrubber) -> Int {
        return UserImages.standard.images.count
    }
    
    func scrubber(_ scrubber: NSScrubber, viewForItemAt index: Int) -> NSScrubberItemView {
        let cell = NSScrubberImageItemView(frame: NSRect(x: 0, y: 0, width: 50, height: 30))
        if index >= UserImages.standard.images.count {
            return cell
        }
        cell.image = UserImages.standard.images[index].image
        cell.imageAlignment = .alignCenter
        return cell
    }
}

extension MainWindow: NSScrubberDelegate {
    func scrubber(_ scrubber: NSScrubber, didSelectItemAt selectedIndex: Int) {
        guard let cvc = window?.contentViewController as? ViewController else { return }
        cvc.filesView.manualScroll(to: selectedIndex + 1)
    }
}
