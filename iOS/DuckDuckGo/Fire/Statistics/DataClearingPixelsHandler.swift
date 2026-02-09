//
//  DataClearingHandler.swift
//  DuckDuckGo
//
//  Copyright © 2026 DuckDuckGo. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import History

struct DataClearingBurnTabsPixelsHandler: DataClearingPixelsHandling {
    
    let dataClearingPixelsResporter: DataClearingPixelsReporter
    
    init(dataClearingPixelsReporter: DataClearingPixelsReporter = .init()) {
        self.dataClearingPixelsResporter = dataClearingPixelsReporter
    }
    
    func fireErrorPixel(_ error: Error) {
        dataClearingPixelsResporter.fireErrorPixel(DataClearingPixels.burnTabsError(error))
    }
    
    func fireDurationPixel(from startTime: CFTimeInterval) {}
    
    func fireDurationPixel(from startTime: CFTimeInterval, at step: String) {}
    
    func fireHasResiduePixel() {}
    
    func fireHasResiduePixel(at step: String) {}
}

struct DataClearingBurnHistoryPixelsHandler: DataClearingPixelsHandling {
    
    let dataClearingPixelsResporter: DataClearingPixelsReporter
    
    init(dataClearingPixelsReporter: DataClearingPixelsReporter = .init()) {
        self.dataClearingPixelsResporter = dataClearingPixelsReporter
    }
    
    func fireErrorPixel(_ error: Error) {
        dataClearingPixelsResporter.fireErrorPixel(DataClearingPixels.burnHistoryError(error))
    }
    
    func fireDurationPixel(from startTime: CFTimeInterval) {
        dataClearingPixelsResporter.fireDurationPixel(DataClearingPixels.burnHistoryDuration, from: startTime)
    }
    
    func fireDurationPixel(from startTime: CFTimeInterval, at step: String) {}
    
    func fireHasResiduePixel() {}
    
    func fireHasResiduePixel(at step: String) {}
}


struct DataClearingBurnWebCachePixelsHandler: DataClearingPixelsHandling {
    
    let dataClearingPixelsResporter: DataClearingPixelsReporter
    
    init(dataClearingPixelsReporter: DataClearingPixelsReporter = .init()) {
        self.dataClearingPixelsResporter = dataClearingPixelsReporter
    }
    
    func fireErrorPixel(_ error: Error) {
        dataClearingPixelsResporter.fireErrorPixel(DataClearingPixels.burnTabsError(error))
    }
    
    func fireDurationPixel(from startTime: CFTimeInterval) {}
    
    func fireDurationPixel(from startTime: CFTimeInterval, at step: String) {}
    
    func fireHasResiduePixel() {}
    
    func fireHasResiduePixel(at step: String) {}
}
