//
//  CastChannel.swift
//  OpenCastSwift
//
//  Created by Miles Hollingsworth on 4/22/18
//  Copyright © 2018 Miles Hollingsworth. All rights reserved.
//

import Foundation
import SwiftyJSON

open class CastChannel {
    let namespace: String
    weak var requestDispatcher: RequestDispatchable!

    init(namespace: String) {
        self.namespace = namespace
    }

    open func handleResponse(_: JSON, sourceId _: String) {
        //    print(json)
    }

    open func handleResponse(_: Data, sourceId _: String) {
        print("\n--Binary response--\n")
    }

    public func send(_ request: CastRequest, response: CastResponseHandler? = nil) {
        requestDispatcher.send(request, response: response)
    }
}
