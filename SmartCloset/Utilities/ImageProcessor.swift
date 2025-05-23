import UIKit
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

class ImageProcessor {
    static let shared = ImageProcessor()
    private let context = CIContext()
    private init() {}
    
    // MARK: - Background Removal
    func removeBackground(from image: UIImage, completion: @escaping (UIImage?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }
        
        // Create VNRequest for person segmentation
        let request = VNGeneratePersonSegmentationRequest()
        request.qualityLevel = .accurate
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
                guard let mask = request.results?.first else {
                    DispatchQueue.main.async { completion(nil) }
                    return
                }
                
                // Convert mask to CIImage
                let maskImage = CIImage(cvPixelBuffer: mask.pixelBuffer)
                
                // Create CIImage from original image
                let inputImage = CIImage(cgImage: cgImage)
                
                // Scale mask to match input image size
                let scaleX = inputImage.extent.width / maskImage.extent.width
                let scaleY = inputImage.extent.height / maskImage.extent.height
                let scaledMask = maskImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
                
                // Create blend filter
                let filter = CIFilter.blendWithMask()
                filter.inputImage = inputImage
                filter.backgroundImage = CIImage(color: .clear)
                filter.maskImage = scaledMask
                
                guard let outputImage = filter.outputImage,
                      let outputCGImage = self.context.createCGImage(outputImage, from: outputImage.extent) else {
                    DispatchQueue.main.async { completion(nil) }
                    return
                }
                
                let finalImage = UIImage(cgImage: outputCGImage)
                DispatchQueue.main.async { completion(finalImage) }
            } catch {
                print("Error removing background: \(error)")
                DispatchQueue.main.async { completion(nil) }
            }
        }
    }
    
    // MARK: - Color Analysis
    func analyzeColors(in image: UIImage, completion: @escaping ([(color: UIColor, percentage: Float)]) -> Void) {
        guard let cgImage = image.cgImage else {
            completion([])
            return
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNGenerateImageFeaturePrintRequest()
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([request])
                
                // Create a smaller version of the image for color analysis
                let size = CGSize(width: 64, height: 64)
                UIGraphicsBeginImageContextWithOptions(size, false, 1)
                image.draw(in: CGRect(origin: .zero, size: size))
                guard let resizedImage = UIGraphicsGetImageFromCurrentImageContext() else {
                    UIGraphicsEndImageContext()
                    DispatchQueue.main.async { completion([]) }
                    return
                }
                UIGraphicsEndImageContext()
                
                // Analyze colors
                guard let imageData = resizedImage.cgImage?.dataProvider?.data,
                      let data = CFDataGetBytePtr(imageData) else {
                    DispatchQueue.main.async { completion([]) }
                    return
                }
                
                var colors: [UIColor: Int] = [:]
                let totalPixels = Int(size.width * size.height)
                
                for y in 0..<Int(size.height) {
                    for x in 0..<Int(size.width) {
                        let offset = 4 * (y * Int(size.width) + x)
                        let color = UIColor(
                            red: CGFloat(data[offset]) / 255.0,
                            green: CGFloat(data[offset + 1]) / 255.0,
                            blue: CGFloat(data[offset + 2]) / 255.0,
                            alpha: CGFloat(data[offset + 3]) / 255.0
                        )
                        colors[color, default: 0] += 1
                    }
                }
                
                // Convert to percentages and sort
                let sortedColors = colors.map { (color: $0.key, percentage: Float($0.value) / Float(totalPixels)) }
                    .sorted { $0.percentage > $1.percentage }
                    .prefix(5) // Get top 5 colors
                
                DispatchQueue.main.async {
                    completion(Array(sortedColors))
                }
            } catch {
                print("Error analyzing colors: \(error)")
                DispatchQueue.main.async { completion([]) }
            }
        }
    }
    
    // MARK: - Image Enhancement
    func enhanceImage(_ image: UIImage) -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }
        
        // Apply a series of adjustments
        let filters: [(CIFilter, Float)] = [
            (CIFilter.colorControls(), 1.1),  // Saturation
            (CIFilter.exposureAdjust(), 0.5), // Exposure
            (CIFilter.sharpenLuminance(), 0.3) // Sharpness
        ]
        
        var processedImage = ciImage
        
        for (filter, intensity) in filters {
            filter.setValue(processedImage, forKey: kCIInputImageKey)
            
            switch filter {
            case is CIColorControls:
                (filter as! CIColorControls).saturation = intensity
                (filter as! CIColorControls).brightness = 0.05
                (filter as! CIColorControls).contrast = 1.05
            case is CIExposureAdjust:
                (filter as! CIExposureAdjust).ev = intensity
            case is CISharpenLuminance:
                (filter as! CISharpenLuminance).sharpness = intensity
            default:
                break
            }
            
            if let outputImage = filter.outputImage {
                processedImage = outputImage
            }
        }
        
        // Convert back to UIImage
        guard let cgImage = context.createCGImage(processedImage, from: processedImage.extent) else {
            return image
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: - Effects
    enum ImageEffect {
        case vintage
        case noir
        case chrome
        case fade
        case instant
    }
    
    func applyEffect(_ effect: ImageEffect, to image: UIImage) -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }
        
        let filter: CIFilter? = {
            switch effect {
            case .vintage:
                let filter = CIFilter.sepiaTone()
                filter.intensity = 0.8
                return filter
            case .noir:
                return CIFilter.photoEffectNoir()
            case .chrome:
                return CIFilter.photoEffectChrome()
            case .fade:
                let filter = CIFilter.colorControls()
                filter.saturation = 0.6
                filter.brightness = 0.1
                return filter
            case .instant:
                return CIFilter.photoEffectInstant()
            }
        }()
        
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        
        guard let outputImage = filter?.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return image
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: - Thumbnail Generation
    func generateThumbnail(for image: UIImage, size: CGSize = CGSize(width: 100, height: 100)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    // MARK: - Utility Functions
    func extractDominantColor(from image: UIImage) -> UIColor {
        guard let inputImage = CIImage(image: image) else { return .clear }
        
        let extentVector = CIVector(x: inputImage.extent.origin.x,
                                  y: inputImage.extent.origin.y,
                                  z: inputImage.extent.size.width,
                                  w: inputImage.extent.size.height)
        
        guard let filter = CIFilter(name: "CIAreaAverage",
                                  parameters: [kCIInputImageKey: inputImage,
                                             kCIInputExtentKey: extentVector]) else {
            return .clear
        }
        
        guard let outputImage = filter.outputImage else { return .clear }
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        context.render(outputImage,
                      toBitmap: &bitmap,
                      rowBytes: 4,
                      bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                      format: .RGBA8,
                      colorSpace: CGColorSpaceCreateDeviceRGB())
        
        return UIColor(red: CGFloat(bitmap[0]) / 255,
                      green: CGFloat(bitmap[1]) / 255,
                      blue: CGFloat(bitmap[2]) / 255,
                      alpha: CGFloat(bitmap[3]) / 255)
    }
} 