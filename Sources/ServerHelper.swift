/*****************************************************************************************************
 * Copyright 2016 SPECURE GmbH
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *****************************************************************************************************/

import Foundation
import Alamofire
import AlamofireObjectMapper
import ObjectMapper

///
class ServerHelper {

    ///
    class func configureAlamofireManager() -> Alamofire.SessionManager {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 30 // seconds
        configuration.timeoutIntervalForResource = 30

        configuration.allowsCellularAccess = true
        configuration.httpShouldUsePipelining = true

        // Set user agent
        if let userAgent = UserDefaults.getRequestUserAgent() {
            configuration.httpAdditionalHeaders = [
                "User-Agent": userAgent,
                "Accept-Language":PREFFERED_LANGUAGE
            ]
        }
        
        // print(Bundle.main.preferredLocalizations)

        return Alamofire.SessionManager(configuration: configuration)
    }

    ///
    class func requestArray<T: BasicResponse>(_ manager: Alamofire.SessionManager, baseUrl: String?, method: Alamofire.HTTPMethod, path: String, requestObject: BasicRequest?, success: @escaping (_ response: [T]) -> (), error failure: @escaping ErrorCallback) {
        // add basic request values (TODO: make device independent -> for osx, tvos)

        var parameters: [String: AnyObject]?

        if let reqObj = requestObject {
            BasicRequestBuilder.addBasicRequestValues(reqObj)

            parameters = reqObj.toJSON() as [String : AnyObject]?

            logger.debug { () -> String in 
                if let jsonString = Mapper().toJSONString(reqObj, prettyPrint: true) {
                    return "Requesting \(path) with object: \n\(jsonString)"
                }

                return "Requesting \(path) with object: <json serialization failed>"
            }
        }

        var encoding: ParameterEncoding = JSONEncoding.default
        if method == .get || method == .delete { // GET and DELETE request don't support JSON bodies...
            encoding = URLEncoding.default
        }
        
        let basePath = (baseUrl != nil ? baseUrl! : "") + path

        manager
            .request(basePath, method: method, parameters: parameters, encoding: encoding, headers: [:])
 // maybe use alamofire router later? (https://grokswift.com/router/)
            .validate() // https://github.com/Alamofire/Alamofire#validation // need custom code to get body from error (see https://github.com/Alamofire/Alamofire/issues/233)
            /*.responseString { response in
                logger.debug {
                    debugPrint(response)
                    return "Response for \(path): \n\(response.result.value)"
                }
            }*/
            
            .responseArray { (response: DataResponse<[T]>) in
                switch response.result {
                case .success:
                    if let responseArray: [T] = response.result.value {

                        logger.debug {
                            debugPrint(response)

                            if let jsonString = Mapper().toJSONString(responseArray, prettyPrint: true) {
                                return "Response for \(path) with object: \n\(jsonString)"
                            }

                            return "Response for \(path) with object: <json serialization failed>"
                        }

                        success(responseArray)
                    }
                case .failure(let error):
                    logger.debug("\(error)") // TODO: error callback

                    /*if let responseObj = response.result.value as? String {
                     logger.debug("error msg from server: \(responseObj)")
                     }*/

                    failure(error as Error)
                }
            }
    }

    ///
    class func request<T: BasicResponse>(_ manager: Alamofire.SessionManager, baseUrl: String?, method: Alamofire.HTTPMethod, path: String, requestObject: BasicRequest?, success:  @escaping (_ response: T) -> (), error failure: @escaping ErrorCallback) {
        // add basic request values (TODO: make device independent -> for osx, tvos)

        var parameters: [String: AnyObject]?

        if let reqObj = requestObject {
            BasicRequestBuilder.addBasicRequestValues(reqObj)

            parameters = reqObj.toJSON() as [String : AnyObject]?

            logger.debug { () -> String in 
                if let jsonString = Mapper().toJSONString(reqObj, prettyPrint: true) {
                    return "Requesting \(path) with object: \n\(jsonString)"
                }

                return "Requesting \(path) with object: <json serialization failed>"
            }
        }
        

        var encoding: ParameterEncoding = JSONEncoding.default
        if method == .get || method == .delete { // GET and DELETE request don't support JSON bodies...
            encoding = URLEncoding.default
        }
        let url = (baseUrl != nil ? baseUrl! : "") + path
        
        manager
            .request(url, method: method, parameters: parameters, encoding: encoding, headers: nil)
    // maybe use alamofire router later? (https://grokswift.com/router/)
            .validate() // https://github.com/Alamofire/Alamofire#validation // need custom code to get body from error (see https://github.com/Alamofire/Alamofire/issues/233)
        
            .responseObject { (response: DataResponse<T>) in
                switch response.result {
                case .success:
                    if let responseObj:T = response.result.value {
                        
                        logger.debug {
                            debugPrint(response)

                            if let jsonString = Mapper().toJSONString(responseObj, prettyPrint: true) {
                                return "Response for \(path) with object: \n\(jsonString)"
                            }

                            return "Response for \(path) with object: <json serialization failed>"
                        }

                        success(responseObj)
                    }
                case .failure(let error):
                    logger.debug("\(error)") // TODO: error callback
                    debugPrint(response)
                    /*if let responseObj = response.result.value as? String {
                     logger.debug("error msg from server: \(responseObj)")
                     }*/

                    failure(error as Error)
                }
            }
    }
}