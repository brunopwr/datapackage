% Generated by roxygen2 (4.0.2): do not edit by hand
\docType{class}
\name{DataObject-class}
\alias{DataObject,}
\alias{DataObject-class}
\title{DataObject wraps raw data with system-level metadata}
\description{
DataObject is a wrapper class that associates raw data with system-level metadata
describing the object.  The system metadata includes attributes such as the object's identifier,
type, size, checksum, owner, version relationship to other objects, access rules, and other critical metadata.
The SystemMetadata is compliant with the DataONE federated repository network's definition of SystemMetadata, and
is encapsulated as a separate object that can be manipulated as needed. Additional science-level and
domain-specific metadata is out-of-scope for SystemMetadata, which is intended only for critical metadata for
managing objects in a repository system.
}
\details{
A DataObject can be constructed by passing the data and SystemMetadata to the new() method, or by passing
an identifier, data, format, user, and DataONE node identifier, in which case a SystemMetadata instance will
be generated with these fields and others that are calculated (such as size and checksum).

Data are associated with the DataObject either by passing it as a \code{'raw'} value to the \code{'dataobj'}
parameter in the constructor, which is then stored in memory, or by passing a fully qualified file path to the
data in the \code{'filename'} parameter, which is then stored on disk.  One of dataobj or filename is required.
Use the \code{'filename'} approach when data are too large to be managed effectively in memory.  Callers can
access the \code{'filename'} slot to get direct access to the file, or can call \code{'getData()'} to retrieve the
contents of the data or file as a raw value (but this will read all of the data into memory).
}
\section{Slots}{

\describe{
\item{\code{sysmeta}}{value of type \code{"SystemMetadata"}, containing the metadata about the object}

\item{\code{data}}{value of type \code{"raw"}, containing the data represented in this object}

\item{\code{filename}}{contains the fully-qualified path to the object data on disk}
}}
\examples{
data <- charToRaw("1,2,3\\n4,5,6\\n")
do <- new("DataObject", "id1", dataobj=data, "text/csv", "uid=jones,DC=example,DC=com", "urn:node:KNB")
getIdentifier(do)
getFormatId(do)
getData(do)
canRead(do, "uid=anybody,DC=example,DC=com")
do <- setPublicAccess(do)
canRead(do, "public")
canRead(do, "uid=anybody,DC=example,DC=com")
#
# Also can create using a file for storage, rather than memory
tf <- tempfile()
con <- file(tf, "wb")
writeBin(data, con)
close(con)
do <- new("DataObject", "id1", format="text/csv", user="uid=jones,DC=example,DC=com", mnNodeId="urn:node:KNB", filename=tf)
}
\author{
Matthew Jones
}
\keyword{classes}

