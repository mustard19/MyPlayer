//
//  MyFileManager.swift
//  MyPlayer
//
//  Created by mustard on 2017/12/28.
//  Copyright © 2017年 mustard. All rights reserved.
//

import Foundation.NSFileManager
import AVFoundation

/// 文件处理
class MyFileManager: NSObject {
    
    // 文件夹名字（存放缓存文件）
    static let directory = "/MyPlayerFiles"
    
    /// 目录设置获取(.../MyPlayerFiles)
    private static func saveDirectory() -> String {
        let m = FileManager.default
        var dir = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first
        dir?.append(directory)// 拼接自定义文件夹名字
        // 创建文件夹
        if !m.fileExists(atPath: dir!) {
            try! m.createDirectory(at: URL(fileURLWithPath: dir!), withIntermediateDirectories: true, attributes: nil)
        }
        return dir!
    }
    
    /// 保存路径
    static func savePath(ofUrlStr url: NSURL) -> String {
        var path = saveDirectory()
        path.append("/")
        path.append(MyFileManager.fileName(ofUrlStr: url))
        return path
    }
    
    /// 文件名字(将URL进行MD5加密)
    static func fileName(ofUrlStr url: NSURL) -> String {
        let name = (url.absoluteString?.MD5)! + ".\(url.pathExtension!)"
//        print("name is \(name)")
        return name
    }
    
    /// 文件路径是否已存在
    static func fileExist(ofPath path: String) -> Bool {
        if FileManager.default.fileExists(atPath: path) {
            return true
        }
        return false
    }
    
    /// 清理缓存文件
    static func cleanAllCache() {
        DispatchQueue.global().async {
            // 连同文件夹清理
            try! FileManager.default.removeItem(atPath: saveDirectory())
            DispatchQueue.main.async(execute: {
                print("缓存清理完毕。。")
            })
        }
    }
}

extension MyFileManager {
    /// 保存文件到本地
    static func saveAVAssetToLocale(ofAVAsset asset: AVAsset, ofURL url: NSURL) {
        let savePath: String = MyFileManager.savePath(ofUrlStr: url)
        if MyFileManager.fileExist(ofPath: savePath) {
//            print("该文件已经缓存过了。。。")
            return
        }
        
        let fileUrl: NSURL = NSURL(fileURLWithPath: savePath)
        
        let avasset: AVAsset? = asset;
        if avasset != nil  {
            let mixComposition = AVMutableComposition()
            // 视频画面轨道
            let videoTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)
            try! videoTrack?.insertTimeRange(CMTimeRangeMake(kCMTimeZero, asset.duration), of: asset.tracks(withMediaType: AVMediaType.video).first!, at: kCMTimeZero)
            // 音频轨道
            let audioTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            try! audioTrack?.insertTimeRange(CMTimeRangeMake(kCMTimeZero, asset.duration), of: asset.tracks(withMediaType: AVMediaType.audio).first!, at: kCMTimeZero)
            // 写入本地
            let export = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality)
            export?.outputURL = fileUrl as URL
            if ((export?.supportedFileTypes) != nil) {
                export?.outputFileType = export?.supportedFileTypes.first
                export?.shouldOptimizeForNetworkUse = true
            export?.exportAsynchronously(completionHandler: {
//                  print("音视频合成文件保存成功")
                })
            }
        }
    }
}
