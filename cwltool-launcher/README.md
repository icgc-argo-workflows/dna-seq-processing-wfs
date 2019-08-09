## cwltool_launcher

### Summary
`cwltool_launcher` is a generic cli wrapper of the cwltool (the reference
implementation of CWL runner). It accepts a cwltool discriptor
file and a set of job parameters as input, then launches cwltool.
Upone successful completion, `cwltool_launcher` will capture output
metadata (via stdout from cwltool) and save it in `output.json`

Note that the code for `cwltool_launcher` will likely move to another
repository later, but for now let's start it here.

### Input
* CWL discriptor input is provided as `--cwl <uri>`. There are a number
of forms for the `uri` the discriptor: a local file: `file://`, a public
`http`/`https`/`ftp` URL, or a GA4GH TRS service URL (like Dockstore).
* All other job parameters are provided as `--input-json-str`, the value
is a str version of JSON which contains key-value pairs same as how they
are defined in the wrapped cwl discriptor. `cwltool_launcher` will then
use `cwltool` template function to generate template and populate the
template with values encoded in the `input-json-str`.

### Output
Upon successful completion of a `cwltool` run, stdout will be output metadata
in JSON format, the `cwltool_launcher` will capture it and transform it to
simplified version of JSON with key-value pair in a file named `output.json`.
`output.json` can be used by any following steps if any. Open question: should
we keep the original `cwltoo` metadata output? If so, how do we pass it on?
Should we just include it as one of the key-value pairs in `output.json`?
