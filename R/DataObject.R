#
#   This work was created by participants in the DataONE project, and is
#   jointly copyrighted by participating institutions in DataONE. For
#   more information on DataONE, see our web site at http://dataone.org.
#
#     Copyright 2011-2015
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

#' DataObject wraps raw data with system-level metadata
#' @description DataObject is a wrapper class that associates raw data with system-level metadata 
#' describing the object.  The system metadata includes attributes such as the object's identifier, 
#' type, size, checksum, owner, version relationship to other objects, access rules, and other critical metadata.
#' The SystemMetadata is compliant with the DataONE federated repository network's definition of SystemMetadata, and
#' is encapsulated as a separate object that can be manipulated as needed. Additional science-level and
#' domain-specific metadata is out-of-scope for SystemMetadata, which is intended only for critical metadata for
#' managing objects in a repository system.
#' @details   
#' A DataObject can be constructed by passing the data and SystemMetadata to the new() method, or by passing
#' an identifier, data, format, user, and DataONE node identifier, in which case a SystemMetadata instance will
#' be generated with these fields and others that are calculated (such as size and checksum).
#' 
#' Data are associated with the DataObject either by passing it as a \code{'raw'} value to the \code{'dataobj'}
#' parameter in the constructor, which is then stored in memory, or by passing a fully qualified file path to the 
#' data in the \code{'filename'} parameter, which is then stored on disk.  One of dataobj or filename is required.
#' Use the \code{'filename'} approach when data are too large to be managed effectively in memory.  Callers can
#' access the \code{'filename'} slot to get direct access to the file, or can call \code{'getData()'} to retrieve the
#' contents of the data or file as a raw value (but this will read all of the data into memory).
#' 
#' @slot sysmeta value of type \code{"SystemMetadata"}, containing the metadata about the object
#' @slot data value of type \code{"raw"}, containing the data represented in this object
#' @slot filename contains the fully-qualified path to the object data on disk
#' @author Matthew Jones
#' @aliases DataObject, DataObject-class
#' @keywords classes
#' @import methods
#' @include dmsg.R
#' @include SystemMetadata.R
#' @examples
#' data <- charToRaw("1,2,3\n4,5,6\n")
#' do <- new("DataObject", "id1", dataobj=data, "text/csv", "uid=jones,DC=example,DC=com", "urn:node:KNB")
#' getIdentifier(do)
#' getFormatId(do)
#' getData(do)
#' canRead(do, "uid=anybody,DC=example,DC=com")
#' do <- setPublicAccess(do)
#' canRead(do, "public")
#' canRead(do, "uid=anybody,DC=example,DC=com")
#' #
#' # Also can create using a file for storage, rather than memory
#' tf <- tempfile()
#' con <- file(tf, "wb")
#' writeBin(data, con)
#' close(con)
#' do <- new("DataObject", "id1", format="text/csv", user="uid=jones,DC=example,DC=com", mnNodeId="urn:node:KNB", filename=tf)
setClass("DataObject", slots = c(
    sysmeta                 = "SystemMetadata",
    data                    = "raw",
    filename                = "character"
    )
)

##########################
## DataObject constructors
##########################

#' Construct a DataObject instance.
#' @param ... Additional arguments
#' @return a DataObject
#' @export
setGeneric("DataObject", function(...) { 
    standardGeneric("DataObject")
})

#' Intialize a DataObject
#' When initializing a DataObject using passed in data, one can either pass 
#' in the \code{'id'} param as a \code{'SystemMetadata'} object, or as a \code{'character'} string 
#' representing the identifier for an object along with parameters for format, user,and associated member node.
#' If \code{'data'} is not missing, the \code{'data'} param holds the \code{'raw'} data.  Otherwise, the
#' \code{'filename'} parameter must be provided, and points at a file containing the bytes of the data.
#' @details If filesystem storage is used for the data associated with a DataObject, care must be
#' taken to not modify or remove that file in R or via other facilities while the DataObject exists in the R session.
#' Changes to the object are not detected and will result in unexpected results.
#' @param .Object the DataObject instance to be initialized
#' @param id the identifier for the DataObject, unique within its repository
#' @param dataobj the bytes of the data for this object in \code{'raw'} format, optional if \code{'filename'} is provided
#' @param format the format identifier for the object (see \url{'http://cn.dataone.org/cn/v1/formats'})
#' @param user the identity of the user owning the package, typically in X.509 format
#' @param mnNodeId the node identifier for the repository to which this object belings
#' @param filename the filename for the fully qualified path to the data on disk, optional if \code{'data'} is provided
#' @import digest
setMethod("initialize", "DataObject", function(.Object, id, dataobj=NA, format=NA, user=NA, mnNodeId=NA, filename=as.character(NA)) {
    
    # Validate: either dataobj or filename must be provided
    if (is.na(dataobj[[1]]) && is.na(filename)) {
        message("Either the dataobj parameter containing raw data or the file parameter with a file reference to the data must be provided.")
        return(NULL)
    }
    
    # Validate: dataobj must be raw if provided
    if (!is.na(dataobj[[1]])) {
        stopifnot(is.raw(dataobj))    
    }
    
    # Validate: file must have content if provided
    if (!is.na(filename)) {
        fileinfo <- file.info(filename)
        stopifnot(fileinfo$size > 0)    
    }
    
    if (typeof(id) == "character") {
        dmsg("@@ DataObject-class:R initialize as character")
        
        # Build a SystemMetadata object describing the data
        if (is.na(dataobj[[1]])) {
            size <- fileinfo$size
            sha1 <- digest(filename, algo="sha1", serialize=FALSE, file=TRUE)
        } else {
            size <- length(dataobj)
            sha1 <- digest(dataobj, algo="sha1", serialize=FALSE, file=FALSE)
        }
        .Object@sysmeta <- new("SystemMetadata", identifier=id, formatId=format, size=size, submitter=user, rightsHolder=user, checksum=sha1, originMemberNode=mnNodeId, authoritativeMemberNode=mnNodeId)
        if (!is.na(dataobj[[1]])) { 
            .Object@data <- dataobj
        }
        .Object@filename <- filename
    } else if (typeof(id) == "S4" && class(id) == "SystemMetadata") {
        .Object@sysmeta <- id
        if (!is.na(dataobj[[1]])) { 
            .Object@data <- dataobj
        }
        .Object@filename <- filename
    }
    
    return(.Object)
})

#' Get the data content of a specified data object
#' 
#' @param x  DataObject or DataPackage: the data structure from where to get the data
#' @param id Missing or character: if \code{'x'} is DataPackage, the identifier of the
#' package member to get data from
#' @param ... Additional arguments
#' @return raw representation of the data
#' @aliases getData
#' @export
setGeneric("getData", function(x, id=NA, ...) {
    standardGeneric("getData")
})

#' @describeIn getData
#' @aliases getData
setMethod("getData", signature("DataObject"), function(x) {
    if (is.na(x@filename)) {
        return(x@data)
    } else {
        # TODO: read the file from disk and return the contents
        stopifnot(!is.na(x@filename))
        fileinfo <- file.info(x@filename)
        con <- file(x@filename, "rb")
        temp <- readBin(con, raw(), x@sysmeta@size)
        close(con)
        return(temp)
    }
})

#' Get the Identifier of the DataObject
#' @param x DataObject
#' @param ... (not yet used)
#' @return the identifier
#' @aliases getIdentifier
#' @export
setGeneric("getIdentifier", function(x, ...) {
    standardGeneric("getIdentifier")
})

#' @describeIn getIdentifier
#' @aliases getIdentifier
setMethod("getIdentifier", signature("DataObject"), function(x) {
	return(x@sysmeta@identifier)
})

#' Get the FormatId of the DataObject
#' @param x DataObject
#' @param ... (not yet used)
#' @return the formatId
#' @aliases getFormatId
#' @export
setGeneric("getFormatId", function(x, ...) {
			standardGeneric("getFormatId")
		})

#' @describeIn getFormatId
#' @aliases getFormatId
setMethod("getFormatId", signature("DataObject"), function(x) {
    return(x@sysmeta@formatId)
})

#' Add a Rule to the AccessPolicy to make the object publicly readable
#' 
#' To be called prior to creating the object in DataONE.  When called before 
#' creating the object, adds a rule to the access policy that makes this object
#' publicly readable.  If called after creation, it will only change the system
#' metadata locally, and will not have any affect. 
#' @param x DataObject
#' @param ... (not yet used)
#' @return DataObject with modified access rules
#' @aliases setPublicAccess
#' @export
setGeneric("setPublicAccess", function(x, ...) {
  standardGeneric("setPublicAccess")
})

#' @describeIn setPublicAccess
#' @aliases setPublicAccess
setMethod("setPublicAccess", signature("DataObject"), function(x) {
    # Check if public: read is already set, and if not, set it
    if (!hasAccessRule(x@sysmeta, "public", "read")) {
        x@sysmeta <- addAccessRule(x@sysmeta, "public", "read")
    }
    return(x)
})

#' Test whether the provided subject can read an object.
#' 
#' Using the AccessPolicy, tests whether the subject has read permission
#' for the object.  This method is meant work prior to submission to a repository, 
#' and will show the permissions that would be enfirced by the repository on submission.
#' Currently it only uses the AccessPolicy to determine who can read (and not the rightsHolder field,
#' which always can read an object).  If an object has been granted read access by the
#' special "public" subject, then all subjects have read access.
#' @details The subject name used in both the AccessPolicy and in the \code{'subject'}
#' argument to this method is a string value, but is generally formatted as an X.509
#' name formatted according to RFC 2253.
#' @param x DataObject
#' @param subject : the subject name of the person/system to check for read permissions
#' @param ... Additional arguments
#' @return boolean TRUE if the subject has read permission, or FALSE otherwise
#' @aliases canRead
#' @export
setGeneric("canRead", function(x, subject, ...) {
  standardGeneric("canRead")
})

#' @describeIn canRead
#' @export
setMethod("canRead", signature("DataObject", "character"), function(x, subject) {

    canRead <- hasAccessRule(x@sysmeta, "public", "read") | hasAccessRule(x@sysmeta, subject, "read")
	return(canRead)
})
