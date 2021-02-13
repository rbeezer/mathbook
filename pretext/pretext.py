# ********************************************************************
# Copyright 2010-2020 Robert A. Beezer
#
# This file is part of PreTeXt.
#
# PreTeXt is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 or version 3 of the
# License (at your option).
#
# PreTeXt is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with PreTeXt.  If not, see <http://www.gnu.org/licenses/>.
# *********************************************************************

# 2020-05-20: this module expects Python 3.4 or newer

#############################
#
#  Math as LaTeX on web pages
#
#############################

def mathjax_latex(xml_source, pub_file, out_file, dest_dir, math_format):
    """Convert PreTeXt source to a structured file of representations of mathematics"""
    # formats:  'svg', 'mml', 'nemeth', 'speech', 'kindle'
    # Internal calls will specify out_file with complete path
    # External calls might only specify a destination directory
    import os.path, subprocess
    import re, os, fileinput # for &nbsp; fix


    _verbose('converting LaTeX from {} into {} format'.format(xml_source, math_format))
    _debug('converting LaTeX from {} into {} format'.format(xml_source, math_format))

    # construct filenames for pre- and post- XSL stylesheets in xsl/support
    extraction_xslt = os.path.join(get_ptx_xsl_path(), 'support/extract-math.xsl')
    cleaner_xslt    = os.path.join(get_ptx_xsl_path(), 'support/package-math.xsl')

    # Extraction stylesheet makes a simple, mock web page for MathJax
    # And MathJax executables preserve the page while changing the math
    tmp_dir = get_temporary_directory()
    mjinput  = os.path.join(tmp_dir, 'mj-input-latex.html')
    mjintermediate = os.path.join(tmp_dir, 'mj-intermediate.html')
    mjoutput = os.path.join(tmp_dir, 'mj-output-{}.html'.format(math_format))

    _debug('temporary directory for MathJax work: {}'.format(tmp_dir))
    _debug('extracting LaTeX from {} and collected in {}'.format(xml_source, mjinput))

    # SVG, MathML, and PNG are visual and we help authors move punctuation into
    # displays, but not into inline versions.  Nemeth braille and speech are not,
    # so we leave punctuation outside.
    if math_format in ['svg', 'mml', 'kindle']:
        punctuation = 'display'
    elif math_format in ['nemeth', 'speech']:
        punctuation = 'none'
    params = {}
    params['math.punctuation'] = punctuation
    if pub_file:
        params['publisher'] = pub_file
    xsltproc(extraction_xslt, xml_source, mjinput, None, params)

    # shell out to process with MathJax/SRE node program
    _debug('calling MathJax to convert LaTeX from {} into raw representations in {}'.format(mjinput, mjoutput))

    # process with  pretext.js  executable from  MathJax (Davide Cervone, Volker Sorge)
    node_exec_cmd = get_executable_cmd('node')
    mjsre_page = os.path.join(get_ptx_path(), 'script', 'mjsre', 'mj-sre-page.js')
    output = {
        'svg': 'svg',
        'kindle': 'mathml',
        'nemeth': 'braille',
        'speech': 'speech',
        'mml': 'mathml'
    }
    try:
        mj_var = output[math_format]
    except KeyError:
        raise ValueError('PTX:ERROR: incorrect format ("{}") for MathJax conversion'.format(math_format))
    mj_option = '--' + mj_var
    mj_tag = 'mj-' + mj_var
    mjpage_cmd = node_exec_cmd + [mjsre_page, mj_option, mjinput]
    outfile = open(mjoutput, 'w')
    subprocess.run(mjpage_cmd, stdout=outfile)

    # the 'mjpage' executable converts spaces inside of a LaTeX
    # \text{} into &nbsp; entities, which is a good idea, and
    # fine for HTML, but subsequent conversions expecting XHTML
    # do not like &nbsp; nor &#xa0.  Be careful just below, as
    # repl contains a *non-breaking space* not a generic space.
    orig = '&nbsp;'
    repl = ' '
    xhtml_elt = re.compile(orig)
    # the inplace facility of the fileinput module gets
    # confused about temporary backup files if the working
    # directory is not where the file lives
    # Also, print() here actual writes on the file, as
    # another facility of the fileinput module, but we need
    # to kill the "extra" newline that print() creates
    owd = os.getcwd()
    os.chdir(tmp_dir)
    html_file = mjoutput
    for line in fileinput.input(html_file, inplace=1):
        print(xhtml_elt.sub(repl, line), end='')
    os.chdir(owd)

    # clean up and package MJ representations, font data, etc
    derivedname = get_output_filename(xml_source, out_file, dest_dir, '-' + math_format + '.xml')
    _debug('packaging math as {} from {} into XML file {}'.format(math_format, mjoutput, out_file))
    xsltproc(cleaner_xslt, mjoutput, derivedname)
    _verbose('XML file of math representations deposited as {}'.format(derivedname))


##############################################
#
#  Graphics Language Extraction and Processing
#
##############################################

def asymptote_conversion(xml_source, pub_file, stringparams, xmlid_root, dest_dir, outformat):
    """Extract asymptote code for diagrams and convert to graphics formats"""
    # stringparams is a dictionary, best for lxml parsing
    import os.path # join()
    import os, subprocess, shutil, glob

    _verbose('converting Asymptote diagrams from {} to {} graphics for placement in {}'.format(xml_source, outformat.upper(), dest_dir))
    tmp_dir = get_temporary_directory()
    _debug("temporary directory: {}".format(tmp_dir))
    asy_executable_cmd = get_executable_cmd('asy')
    # TODO why this debug line? get_executable_cmd() outputs the same debug info
    _debug("asy executable: {}".format(asy_executable_cmd[0]))
    ptx_xsl_dir = get_ptx_xsl_path()
    extraction_xslt = os.path.join(ptx_xsl_dir, 'extract-asymptote.xsl')
    # support publisher file, subtree argument
    if pub_file:
        stringparams['publisher'] = pub_file
    if xmlid_root:
        stringparams['subtree'] = xmlid_root
    # no output (argument 3), stylesheet writes out per-image file
    # outputs a list of ids, but we just loop over created files
    _verbose("extracting Asymptote diagrams from {}".format(xml_source))
    _verbose('string parameters passed to extraction stylesheet: {}'.format(stringparams))
    xsltproc(extraction_xslt, xml_source, None, tmp_dir, stringparams)
    # Resulting *.asy files are in tmp_dir, switch there to work
    os.chdir(tmp_dir)
    devnull = open(os.devnull, 'w')
    # perhaps replace following stock advisory with a real version
    # check using the (undocumented) distutils.version module, see:
    # https://stackoverflow.com/questions/11887762/how-do-i-compare-version-numbers-in-python
    proc = subprocess.Popen([asy_executable_cmd[0], '--version'], stderr=subprocess.PIPE)
    # bytes -> ASCII, strip final newline
    asyversion = proc.stderr.read().decode('ascii')[:-1]
    # simply copy for source file output
    if outformat == 'source':
        for asydiagram in os.listdir(tmp_dir):
            _verbose("copying source file {}".format(asydiagram))
            shutil.copy2(asydiagram, dest_dir)
    # consolidated process for four possible output formats
    if outformat in ['html', 'svg', 'png', 'pdf', 'eps']:
        # build command line to suit
        asy_cli = [asy_executable, '-f', outformat]
        if outformat in ['pdf', 'eps']:
            asy_cli += ['-noprc', '-iconify', '-tex', 'xelatex', '-batchMask']
        elif outformat in ['svg', 'png']:
            asy_cli += ['-render=4', '-tex', 'xelatex', '-iconify']
        # loop over files, doing conversions
        for asydiagram in os.listdir(tmp_dir):
            filebase, _ = os.path.splitext(asydiagram)
            asyout = "{}.{}".format(filebase, outformat)
            asy_cmd = asy_cli + [asydiagram]
            _verbose("converting {} to {}".format(asydiagram, asyout))
            _debug("asymptote conversion {}".format(asy_cmd))
            subprocess.call(asy_cmd, stdout=devnull, stderr=subprocess.STDOUT)
            if os.path.exists(asyout):
                shutil.copy2(asyout, dest_dir)
            else:
                msg = [
                'PTX:WARNING: the Asymptote output {} was not built'.format(asyout),
                '             1. Perhaps your code has errors (try testing in the Asymptote web app).',
                '             2. Or your copy of Asymtote may precede version 2.66 that we expect.',
                '                Not every image can be built in every possible format.',
                '',
                '                Your Asymptote reports its version within the following:',
                '                {}'.format(asyversion)]
                print('\n'.join(msg))


def sage_conversion(xml_source, pub_file, stringparams, xmlid_root, dest_dir, outformat):
    import tempfile, os, os.path, subprocess, shutil, glob
    _verbose('converting Sage diagrams from {} to {} graphics for placement in {}'.format(xml_source, outformat.upper(), dest_dir))
    tmp_dir = get_temporary_directory()
    _debug("temporary directory: {}".format(tmp_dir))
    sage_executable_cmd = get_executable_cmd('sage')
    # TODO why this debug line? get_executable_cmd() outputs the same debug info
    _debug("sage executable: {}".format(sage_executable_cmd[0]))
    ptx_xsl_dir = get_ptx_xsl_path()
    extraction_xslt = os.path.join(ptx_xsl_dir, 'extract-sageplot.xsl')
    _verbose("extracting Sage diagrams from {}".format(xml_source))
    # support publisher file, subtree argument
    if pub_file:
        stringparams['publisher'] = pub_file
    if xmlid_root:
        stringparams['subtree'] = xmlid_root
    xsltproc(extraction_xslt, xml_source, None, tmp_dir, stringparams)
    os.chdir(tmp_dir)
    devnull = open(os.devnull, 'w')
    for sageplot in os.listdir(tmp_dir):
        if outformat == 'source':
            shutil.copy2(sageplot, dest_dir)
        else:
            filebase, _ = os.path.splitext(sageplot)
            sageout = "{0}.{1}".format(filebase, outformat)
            sagepng = "{0}.png".format(filebase, outformat)
            sage_cmd = sage_executable_cmd + [sageplot, outformat]
            _verbose("converting {} to {} (or {} for 3D)".format(sageplot, sageout, sagepng))
            _debug("sage conversion {}".format(sage_cmd))
            subprocess.call(sage_cmd, stdout=devnull, stderr=subprocess.STDOUT)
            # Sage makes PNGs for 3D
            for f in glob.glob(sageout):
                shutil.copy2(f, dest_dir)
            for f in glob.glob(sagepng):
                shutil.copy2(f, dest_dir)

def latex_image_conversion(xml_source, pub_file, stringparams, xmlid_root, data_dir, dest_dir, outformat):
    # stringparams is a dictionary, best for lxml parsing
    import platform # system, machine()
    import os.path # join()
    import subprocess # call() is Python 3.5
    import os, shutil

    _verbose('converting latex-image pictures from {} to {} graphics for placement in {}'.format(xml_source, outformat, dest_dir))
    # for killing output
    devnull = open(os.devnull, 'w')
    tmp_dir = get_temporary_directory()
    _debug("temporary directory for latex-image conversion: {}".format(tmp_dir))
    # NB: next command uses relative paths, so no chdir(), etc beforehand
    if data_dir:
        copy_data_directory(xml_source, data_dir, tmp_dir)
    ptx_xsl_dir = get_ptx_xsl_path()
    _verbose("extracting latex-image pictures from {}".format(xml_source))
    # support publisher file, subtree argument
    if pub_file:
        stringparams['publisher'] = pub_file
    if xmlid_root:
        stringparams['subtree'] = xmlid_root
    _verbose('string parameters passed to extraction stylesheet: {}'.format(stringparams))
    extraction_xslt = os.path.join(ptx_xsl_dir, 'extract-latex-image.xsl')
    # no output (argument 3), stylesheet writes out per-image file
    xsltproc(extraction_xslt, xml_source, None, tmp_dir, stringparams)
    # now work in temporary directory
    os.chdir(tmp_dir)
    # files *only*, from top-level
    files = list(filter(os.path.isfile, os.listdir(tmp_dir)))
    for latex_image in files:
        if outformat == 'source':
            shutil.copy2(latex_image, dest_dir)
            _verbose("copying {} to {}".format(latex_image, dest_dir))
        else:
            filebase, _ = os.path.splitext(latex_image)
            latex_image_pdf = "{}.pdf".format(filebase)
            latex_image_svg = "{}.svg".format(filebase)
            latex_image_png = "{}.png".format(filebase)
            latex_image_eps = "{}.eps".format(filebase)
            tex_executable_cmd = get_executable_cmd('tex')
            # TODO why this debug line? get_executable_cmd() outputs the same debug info
            _debug("tex executable: {}".format(tex_executable_cmd[0]))
            latex_cmd = tex_executable_cmd + ["-interaction=batchmode", latex_image]
            _verbose("converting {} to {}".format(latex_image, latex_image_pdf))
            subprocess.call(latex_cmd, stdout=devnull, stderr=subprocess.STDOUT)
            if not os.path.exists(latex_image_pdf):
                print('PTX:ERROR: There was a problem compiling {} and {} was not created'.format(latex_image,latex_image_pdf))
            pcm_executable_cmd = get_executable_cmd('pdfcrop')
            pcm_cmd = pcm_executable_cmd + [latex_image_pdf, "-o", "cropped-"+latex_image_pdf, "-p", "0", "-a", "-1"]
            _verbose("cropping {} to {}".format(latex_image_pdf, latex_image_pdf))
            subprocess.call(pcm_cmd, stdout=devnull, stderr=subprocess.STDOUT)
            shutil.move("cropped-"+latex_image_pdf, latex_image_pdf)
            if outformat == 'all':
                shutil.copy2(latex_image, dest_dir)
            if (outformat == 'pdf' or outformat == 'all'):
                shutil.copy2(latex_image_pdf, dest_dir)
            if (outformat == 'svg' or outformat == 'all'):
                pdfsvg_executable_cmd = get_executable_cmd('pdfsvg')
                # TODO why this debug line? get_executable_cmd() outputs the same debug info
                _debug("pdfsvg executable: {}".format(pdfsvg_executable_cmd[0]))
                svg_cmd = pdfsvg_executable_cmd + [latex_image_pdf, latex_image_svg]
                _verbose("converting {} to {}".format(latex_image_pdf, latex_image_svg))
                subprocess.call(svg_cmd)
                shutil.copy2(latex_image_svg, dest_dir)
            if (outformat == 'png' or outformat == 'all'):
                # create high-quality png, presumes "convert" executable
                pdfpng_executable_cmd = get_executable_cmd('pdfpng')
                # TODO why this debug line? get_executable_cmd() outputs the same debug info
                _debug("pdfpng executable: {}".format(pdfpng_executable_cmd[0]))
                png_cmd = pdfpng_executable_cmd + ["-density", "300",  latex_image_pdf, "-quality", "100", latex_image_png]
                _verbose("converting {} to {}".format(latex_image_pdf, latex_image_png))
                subprocess.call(png_cmd)
                shutil.copy2(latex_image_png, dest_dir)
            if (outformat == 'eps' or outformat == 'all'):
                pdfeps_executable_cmd = get_executable_cmd('pdfeps')
                # TODO why this debug line? get_executable_cmd() outputs the same debug info
                _debug("pdfeps executable: {}".format(pdfeps_executable_cmd[0]))
                eps_cmd = pdfeps_executable_cmd + ['-eps', latex_image_pdf, latex_image_eps]
                _verbose("converting {} to {}".format(latex_image_pdf, latex_image_eps))
                subprocess.call(eps_cmd)
                shutil.copy2(latex_image_eps, dest_dir)

################################
#
#  WeBWorK Extraction Processing
#
################################

def webwork_to_xml(xml_source, pub_file, stringparams, abort_early, server_params, dest_dir):
    import subprocess, os.path
    import sys # version_info
    import urllib.parse # urlparse()
    import re     # regular expressions for parsing
    import base64  # b64encode()
    import lxml.etree as ET
    import copy
    # at least on Mac installations, requests module is not standard
    try:
        import requests
    except ImportError:
        msg = 'PTX:ERROR: failed to import requests module, is it installed?'
        raise ValueError(msg)

    # N.B. accepting a publisher file and passing it the extraction step
    # runs the risk of specifying a representations file, so there is then
    # nothing left to extract after substitutions.  Only relevant if an
    # assembly step is needed, such as adding in private solutions

    # support publisher file, but not subtree argument
    if pub_file:
        stringparams['publisher'] = pub_file
    _verbose('string parameters passed to extraction stylesheet: {}'.format(stringparams))
    # execute XSL extraction to get back five dictionaries
    # where the keys are the internal-ids for the problems
    # origin, seed, source, pghuman, pgdense
    ptx_xsl_dir = get_ptx_xsl_path()
    extraction_xslt = os.path.join(ptx_xsl_dir, 'extract-pg.xsl')

    # Build dictionaries into a scratch directory/file
    tmp_dir = get_temporary_directory()
    ww_filename = os.path.join(tmp_dir, 'webwork-dicts.txt')
    _debug('WeBWorK dictionaries temporarily in {}'.format(ww_filename))
    xsltproc(extraction_xslt, xml_source, ww_filename, None, stringparams)
    # "run" an assignment for the list of triples of strings
    ww_file = open(ww_filename, 'r')
    problem_dictionaries = ww_file.read()
    ww_file.close()
    # "run" the dictionaries
    # protect backslashes in LaTeX code
    # globals() necessary for success
    exec(problem_dictionaries.replace('\\','\\\\'), globals())

    # verify, construct problem format requestor
    # remove any surrounding white space
    server_params = server_params.strip()
    if (server_params.startswith("(") and server_params.endswith(")")):
        server_params=server_params.strip('()')
        split_server_params = server_params.split(',')
        ww_domain = sanitize_url(split_server_params[0])
        courseID = sanitize_alpha_num_underscore(split_server_params[1])
        userID = sanitize_alpha_num_underscore(split_server_params[2])
        password = sanitize_alpha_num_underscore(split_server_params[3])
        course_password = sanitize_alpha_num_underscore(split_server_params[4])
    else:
        ww_domain = sanitize_url(server_params)
        courseID = 'anonymous'
        userID = 'anonymous'
        password = 'anonymous'
        course_password = 'anonymous'

    ww_domain_ww2 = ww_domain + '/webwork2/'
    ww_domain_path = ww_domain_ww2 + 'html2xml'

    # Establish WeBWorK version
    try:
        landing_page = requests.get(ww_domain_ww2)
    except Exception as e:
        root_cause = str(e)
        msg = ("PTX:ERROR:   There was a problem contacting the WeBWorK server.\n" +
               "             Is there a WeBWorK landing page at {}?\n")
        raise ValueError(msg.format(ww_domain_ww2) + root_cause)

    landing_page_text = landing_page.text
    ww_version_match = re.search(r"WW.VERSION:\s*((\d+)\.(\d+))",landing_page_text,re.I)
    try:
        ww_version = ww_version_match.group(1)
        ww_major_version = int(ww_version_match.group(2))
        ww_minor_version = int(ww_version_match.group(3))
    except AttributeError as e:
        root_cause = str(e)
        msg =  ("PTX:ERROR:   PreTeXt was unable to discern the version of the WeBWorK server.\n" +
                "                         Is there a WeBWorK landing page at {}?\n" +
                "                         And does it display the WeBWorK version?\n")
        raise ValueError(msg.format(ww_domain_ww2))

    if (ww_major_version != 2 or ww_minor_version < 14):
        msg = ("PTX:ERROR:   PreTeXt supports WeBWorK 2.14 and later, and it appears you are attempting to use version: {}\n" +
               "                         Server: {}\n")
        raise ValueError(msg.format(ww_version,ww_domain))

    ww_reps_version = ''
    if (ww_major_version == 2 and (ww_minor_version == 14 or ww_minor_version == 15)):
        # version 1: live problems are embedded in an iframe
        ww_reps_version = '1'
    elif (ww_major_version == 2 and ww_minor_version >= 16):
        # version 1: live problems are injected into a div using javascript
        ww_reps_version = '2'

    # using a "Session()" will pool connection information
    # since we always hit the same server, this should increase performance
    session = requests.Session()

    # begin XML tree
    # then we loop through all problems, appending children
    NSMAP = {"xml" : "http://www.w3.org/XML/1998/namespace"}
    XML = "http://www.w3.org/XML/1998/namespace"
    webwork_representations = ET.Element('webwork-representations', nsmap = NSMAP)
    # lines like this next one micromanage newlines and indentation when we print to file
    webwork_representations.text = "\n  "

    # Choose one of the dictionaries to take its keys as what to loop through
    for problem in sorted(origin):

        # It is more convenient to identify server problems by file path,
        # and PTX problems by internal ID
        problem_identifier = problem if (origin[problem] == 'ptx') else source[problem]

        if origin[problem] == 'server':
            msg = 'building representations of server-based WeBWorK problem'
        elif origin[problem] == 'ptx':
            msg = 'building representations of PTX-authored WeBWorK problem'
        else:
            raise ValueError("PTX:ERROR: problem origin should be 'server' or 'ptx', not '{}'".format(origin[problem]))
        _verbose(msg)

        # make base64 for PTX problems
        if origin[problem] == 'ptx':
            if (ww_reps_version == '2'):
                pgbase64 = base64.b64encode(bytes(pgdense[problem], 'utf-8')).decode("utf-8")
            elif (ww_reps_version == '1'):
                pgbase64 = {}
                for hint_sol in ['hint_yes_solution_yes','hint_yes_solution_no','hint_no_solution_yes','hint_no_solution_no']:
                    pgbase64[hint_sol] = base64.b64encode(bytes(pgdense[hint_sol][problem], 'utf-8'))

        # Construct URL to get static version from server
        # WW server can react to a
        #   URL of a problem stored there already
        #   or a base64 encoding of a problem
        # server_params is tuple rather than dictionary to enforce consistent order in url parameters
        if (ww_reps_version == '2'):
            server_params_source = ('sourceFilePath',source[problem]) if origin[problem] == 'server' else ('problemSource',pgbase64)
        elif (ww_reps_version == '1'):
            server_params_source = ('sourceFilePath',source[problem]) if origin[problem] == 'server' else ('problemSource',pgbase64['hint_yes_solution_yes'])

        server_params = (('answersSubmitted','0'),
                         ('displayMode','PTX'),
                         ('courseID',courseID),
                         ('userID',userID),
                         ('password',password),
                         ('course_password',course_password),
                         ('outputformat','ptx'),
                         server_params_source,
                         ('problemSeed',seed[problem]))

        msg = "sending {} to server to save in {}: origin is '{}'"
        _verbose(msg.format(problem, dest_dir, origin[problem]))
        if origin[problem] == 'server':
            _debug('server-to-ptx: {} {} {} {}'.format(source[problem], ww_domain_path, dest_dir, problem))
        elif origin[problem] == 'ptx':
            if (ww_reps_version == '2'):
                _debug('server-to-ptx: {} {} {} {}'.format(pgdense[problem], ww_domain_path, dest_dir, problem))
            elif (ww_reps_version == '1'):
                _debug('server-to-ptx: {} {} {} {}'.format(pgdense['hint_yes_solution_yes'][problem], ww_domain_path, dest_dir, problem))

        # Ready, go out on the wire
        try:
            response = session.get(ww_domain_path, params=server_params)
        except requests.exceptions.RequestException as e:
            root_cause = str(e)
            msg = "PTX:ERROR: there was a problem collecting a problem,\n Server: {}\nRequest Parameters: {}\n"
            raise ValueError(msg.format(ww_domain_path, server_params) + root_cause)

        # Check for errors with PG processing
        # Get booleans signaling badness: file_empty, no_compile, bad_xml, no_statement
        file_empty = 'ERROR:  This problem file was empty!' in response.text

        no_compile = 'ERROR caught by Translator while processing problem file:' in response.text

        bad_xml = False
        try:
            response_root = ET.fromstring(response.text)
        except:
            response_root = ET.Element('webwork')
            bad_xml = True

        no_statement = False
        if not bad_xml:
            if response_root.find('.//statement') is None:
                no_statement = True
        badness = file_empty or no_compile or bad_xml or no_statement

        # Custom responses for each type of badness
        # message for terminal log
        # tip reminding about -a (abort) option
        # value for @failure attribute in static element
        # base64 for a shell PG problem that simply indicates there was an issue and says what the issue was
        badness_msg = ''
        badness_tip = ''
        badness_type = ''
        badness_base64 = ''
        if file_empty:
            badness_msg = "PTX:ERROR: WeBWorK problem {} was empty\n"
            badness_tip = ''
            badness_type = 'empty'
            badness_base64 = 'RE9DVU1FTlQoKTsKbG9hZE1hY3JvcygiUEdzdGFuZGFyZC5wbCIsIlBHTUwucGwiLCJQR2NvdXJzZS5wbCIsKTtURVhUKGJlZ2lucHJvYmxlbSgpKTtDb250ZXh0KCdOdW1lcmljJyk7CgpCRUdJTl9QR01MCldlQldvcksgUHJvYmxlbSBGaWxlIFdhcyBFbXB0eQoKRU5EX1BHTUwKCkVORERPQ1VNRU5UKCk7'
        elif no_compile:
            badness_msg = "PTX:ERROR: WeBWorK problem {} with seed {} did not compile  \n{}\n"
            badness_tip = '  Use -a to halt with full PG and returned content' if (origin[problem] == 'ptx') else '  Use -a to halt with returned content'
            badness_type = 'compile'
            badness_base64 = 'RE9DVU1FTlQoKTsKbG9hZE1hY3JvcygiUEdzdGFuZGFyZC5wbCIsIlBHTUwucGwiLCJQR2NvdXJzZS5wbCIsKTtURVhUKGJlZ2lucHJvYmxlbSgpKTtDb250ZXh0KCdOdW1lcmljJyk7CgpCRUdJTl9QR01MCldlQldvcksgUHJvYmxlbSBEaWQgTm90IENvbXBpbGUKCkVORF9QR01MCgpFTkRET0NVTUVOVCgpOw=='
        elif bad_xml:
            badness_msg = "PTX:ERROR: WeBWorK problem {} with seed {} does not return valid XML  \n  It may not be PTX compatible  \n{}\n"
            badness_tip = '  Use -a to halt with returned content'
            badness_type = 'xml'
            badness_base64 = 'RE9DVU1FTlQoKTsKbG9hZE1hY3JvcygiUEdzdGFuZGFyZC5wbCIsIlBHTUwucGwiLCJQR2NvdXJzZS5wbCIsKTtURVhUKGJlZ2lucHJvYmxlbSgpKTtDb250ZXh0KCdOdW1lcmljJyk7CgpCRUdJTl9QR01MCldlQldvcksgUHJvYmxlbSBEaWQgTm90IEdlbmVyYXRlIFZhbGlkIFhNTAoKRU5EX1BHTUwKCkVORERPQ1VNRU5UKCk7'
        elif no_statement:
            badness_msg = "PTX:ERROR: WeBWorK problem {} with seed {} does not have a statement tag \n  Maybe it uses something other than BEGIN_TEXT or BEGIN_PGML to print the statement in its PG code \n{}\n"
            badness_tip = '  Use -a to halt with returned content'
            badness_type = 'statement'
            badness_base64 = 'RE9DVU1FTlQoKTsKbG9hZE1hY3JvcygiUEdzdGFuZGFyZC5wbCIsIlBHTUwucGwiLCJQR2NvdXJzZS5wbCIsKTtURVhUKGJlZ2lucHJvYmxlbSgpKTtDb250ZXh0KCdOdW1lcmljJyk7CgpCRUdJTl9QR01MCldlQldvcksgUHJvYmxlbSBEaWQgTm90IEhhdmUgYSBbfHN0YXRlbWVudHxdKiBUYWcKCkVORF9QR01MCgpFTkRET0NVTUVOVCgpOw=='

        # If we are aborting upon recoverable errors...
        if abort_early:
            if badness:
                debugging_help = response.text
                if origin[problem] == 'ptx' and no_compile:
                    debugging_help += "\n" + pghuman[problem]
                raise ValueError(badness_msg.format(problem_identifier, seed[problem], debugging_help))

        # Now a block where we edit the text from the response before using it to build XML
        # First some special handling for verbatim in answers.
        # Then change targets of img (while downloading the original target as an image file)

        # When a PG Math Object is a text string that has to be rendered in a math environment,
        # depending on the string's content and the version of WeBworK, it can come back as:

        # \text{string}            only when the string is built solely from -A-Za-z0-9 ,.;:+=?()[]
        # \verb\x85string\x85      version 2.14 and earlier
        # \verb\x1Fstring\x1F      certain develop branches between 2.14 and 2.15, and WW HTML output for 2.15+
        # {\verb\rstring\r}        WW PTX (and TeX) output starting with 2.15, hopefully stable

        # We would like to replace all instances with \text{string},
        # but in addition to character escaping issues, \text does not behave equally in TeX and MathJax.
        # Certain characters _need_ to be escaped in TeX, but must _not_ be escaped in MathJax.
        # So we make the change after checking that none of the dangerous characters are present,
        # and otherwise leave \verb in place. But we replace the delimiter with the first available
        # "normal" character.
        # \r would be valid XML, but too unpredictable in translations
        # something like \x85 would be vald XML, but may not be OK in some translations

        verbatim_split = re.split(r'(\\verb\x85.*?\x85|\\verb\x1F.*?\x1F|\\verb\r.*?\r)', response.text)
        response_text = ''
        for item in verbatim_split:
            if re.match(r'^\\verb(\x85|\x1F|\r).*?\1$', item):
                (original_delimiter, verbatim_content) = re.search(r'\\verb(\x85|\x1F|\r)(.*?)\1', item).group(1,2)
                if set(['#', '%', '&', '<', '>', '\\', '^', '_', '`', '|', '~']).intersection(set(list(verbatim_content))):
                    index = 33
                    while index < 127:
                        if index in [42, 34, 38, 39, 59, 60, 62] or chr(index) in verbatim_content:
                            # the one character you cannot use with \verb as a delimiter is chr(42), *
                            # the others excluded here are the XML control characters,
                            # and semicolon for good measure (as the closer for escaped characters)
                            index += 1
                        else:
                            break
                    if index == 127:
                        print('PTX:WARNING: Could not find delimiter for verbatim expression')
                        return '!Could not find delimiter for verbatim expression.!'
                    else:
                        response_text += item.replace(original_delimiter, chr(index))
                else:
                    # These three characters are escaped in both TeX and MathJax
                    text_content = verbatim_content.replace('$', '\\$')
                    text_content = text_content.replace('{', '\\{')
                    text_content = text_content.replace('}', '\\}')
                    response_text += '\\text{' + text_content + '}'
            else:
                response_text += item

        # need to loop through content looking for images with pattern:
        #
        #   <image source="relative-path-to-temporary-image-on-server"
        #
        graphics_pattern = re.compile(r'<image.*?source="([^"]*)"')

        # replace filenames, download images with new filenames
        count = 0
        # ww_image_url will be the URL to an image file used by the problem on the ww server
        for match in re.finditer(graphics_pattern, response_text):
            ww_image_url = match.group(1)
            # strip away the scheme and location, if present (e.g 'https://webwork-ptx.aimath.org/')
            ww_image_url_parsed = urllib.parse.urlparse(ww_image_url)
            ww_image_scheme = ww_image_url_parsed.scheme
            ww_image_full_path = ww_image_url_parsed.path
            count += 1
            # split the full path into (path, file). path could theoretically be empty.
            ww_image_path, ww_image_filename = os.path.split(ww_image_full_path)
            # split the filename into (name, extension). extension can be empty or like '.png'.
            ww_image_name, image_extension = os.path.splitext(ww_image_filename)
            # rename, eg, webwork-representations/webwork-5-image-3.png
            ptx_image_name =  problem + '-image-' + str(count)
            ptx_image_filename = ptx_image_name + image_extension
            if ww_image_scheme:
                image_url = ww_image_url
            else:
                image_url = ww_domain + '/' + ww_image_full_path
            # modify PTX problem source to include local versions
            response_text = response_text.replace(ww_image_full_path, 'images/' + ptx_image_filename)
            # download actual image files
            # http://stackoverflow.com/questions/13137817/how-to-download-image-using-requests
            try:
                image_response = session.get(image_url)
            except requests.exceptions.RequestException as e:
                root_cause = str(e)
                msg = "PTX:ERROR: there was a problem downloading an image file,\n URL: {}\n"
                raise ValueError(msg.format(image_url) + root_cause)
            # and save the image itself
            try:
                with open(os.path.join(dest_dir, ptx_image_filename), 'wb') as image_file:
                    image_file.write(image_response.content)
            except Exception as e:
                root_cause = str(e)
                msg = "PTX:ERROR: there was a problem saving an image file,\n Filename: {}\n"
                raise ValueError(os.path.join(dest_dir, ptx_filename) + root_cause)


        # Start appending XML children
        # Use "webwork-reps" as parent tag for the various representations of a problem
        response_root = ET.fromstring(response_text)
        webwork_reps = ET.SubElement(webwork_representations,'webwork-reps')
        webwork_reps.set('version',ww_reps_version)
        webwork_reps.set("{%s}id" % (XML),'extracted-' + problem)
        webwork_reps.set('ww-id',problem)
        webwork_reps.text = "\n    "
        webwork_reps.tail = "\n  "
        static = ET.SubElement(webwork_reps,'static')
        static.text = "\n      "
        static.set('seed',seed[problem])
        if (origin[problem] == 'server'):
            static.set('source',source[problem])

        # If there is "badness"...
        # Build 'shell' problems to indicate failures
        if badness:
            print(badness_msg.format(problem_identifier, seed[problem], badness_tip))
            static.set('failure',badness_type)
            statement = ET.SubElement(static, 'statement')
            p = ET.SubElement(statement, 'p')
            p.text = badness_msg.format(problem_identifier, seed[problem], badness_tip)
            continue

        # Exericse schema is: (statement, hint*, answer*, solution*)
        # Incoming WW may have multiple statement, so we merge them into one.
        # Then write hints in original order.
        # Then convert answerhashes to a sequence of answer.
        # Lastly, write all solutions in original order.
        # For problems with stages, more care is needed to get hints, answers, solutions within the right stage

        # First handle problems where there are no stages
        if response_root.find('.//stage') is None:
            statement = ET.SubElement(static, 'statement')
            statement.text = "\n"
            statements = response_root.findall('.//statement')
            for st in list(statements):
                for child in st:
                    # response_root is an element tree from the response
                    # webwork_represenations is an element tree
                    # we use deepcopy to make sure that when we append we are making new nodes,
                    # not intertangling the two trees
                    chcopy = copy.deepcopy(child)
                    statement.append(chcopy)
            # blocks like this next one micromanage newlines and indentation when we print to file
            for elem in statement.getiterator():
                try:
                    elem.text = elem.text.replace("\n","\n        ")
                except AttributeError:
                    pass
                try:
                    elem.tail = elem.tail.replace("\n","\n        ")
                except AttributeError:
                    pass
            # blocks like this next one micromanage newlines and indentation when we print to file
            last = statement.xpath('./*[last()]')
            if last:
                last[0].tail = "\n      "
            else:
                print('PTX:WARNING: a statement in {} has no content'.format(problem_identifier))
            statement.tail = "\n      "

            hints = response_root.findall('.//hint')
            for ht in list(hints):
                htcopy = copy.deepcopy(ht)
                for elem in htcopy.getiterator():
                    try:
                        elem.text = elem.text.replace("\n","\n        ")
                    except AttributeError:
                        pass
                    try:
                        elem.tail = elem.tail.replace("\n","\n        ")
                    except AttributeError:
                        pass

                last = htcopy.xpath('./*[last()]')
                if last:
                    last[0].tail = "\n      "
                else:
                    print('PTX:WARNING: a hint in {} has no content'.format(problem_identifier))
                htcopy.text = "\n        "
                htcopy.tail = "\n      "

                static.append(htcopy)

            answer_hashes = response_root.find('.//answerhashes')
            if answer_hashes is not None:
                for ans in list(answer_hashes):
                    correct_ans = ans.get('correct_ans','')
                    correct_ans_latex_string = ans.get('correct_ans_latex_string','')
                    if (correct_ans != '' or correct_ans_latex_string != ''):
                        answer = ET.SubElement(static,'answer')
                        answer.text = "\n        "
                        p = ET.SubElement(answer,'p')
                        if correct_ans_latex_string:
                            m = ET.SubElement(p, 'm')
                            m.text = correct_ans_latex_string
                        elif correct_ans:
                            p.text = correct_ans
                        p.tail = "\n      "
                        answer.tail = "\n      "

            solutions = response_root.findall('.//solution')
            for sol in list(solutions):
                solcopy = copy.deepcopy(sol)
                for elem in solcopy.getiterator():
                    try:
                        elem.text = elem.text.replace("\n","\n        ")
                    except AttributeError:
                        pass
                    try:
                        elem.tail = elem.tail.replace("\n","\n        ")
                    except AttributeError:
                        pass

                last = solcopy.xpath('./*[last()]')
                if last:
                    last[0].tail = "\n      "
                else:
                    print('PTX:WARNING: a solution in {} has no content'.format(problem_identifier))
                solcopy.text = "\n        "
                solcopy.tail = "\n      "

                static.append(solcopy)

        else:
            stages = response_root.findall('.//stage')
            for stg in list(stages):
                stage = ET.SubElement(static,'stage')
                stage.text = "\n        "
                statement = ET.SubElement(stage, 'statement')
                statement.text = "\n"
                statements = stg.findall('.//statement')
                for st in list(statements):
                    for child in st:
                        chcopy = copy.deepcopy(child)
                        statement.append(chcopy)
                for elem in statement.getiterator():
                    try:
                        elem.text = elem.text.replace("\n","\n          ")
                    except AttributeError:
                        pass
                    try:
                        elem.tail = elem.tail.replace("\n","\n          ")
                    except AttributeError:
                        pass

                last = statement.xpath('./*[last()]')
                if last:
                    last[0].tail = "\n        "
                else:
                    print('PTX:WARNING: a statement in {} has no content'.format(problem_identifier))
                statement.tail = "\n        "

                hints = stg.findall('.//hint')
                for ht in list(hints):
                    htcopy = copy.deepcopy(ht)
                    for elem in htcopy.getiterator():
                        try:
                            elem.text = elem.text.replace("\n","\n          ")
                        except AttributeError:
                            pass
                        try:
                            elem.tail = elem.tail.replace("\n","\n          ")
                        except AttributeError:
                            pass

                    last = htcopy.xpath('./*[last()]')
                    if last:
                        last[0].tail = "\n        "
                    else:
                        print('PTX:WARNING: a hint in {} has no content'.format(problem_identifier))
                    htcopy.text = "\n          "
                    htcopy.tail = "\n        "

                    stage.append(htcopy)

                answer_hashes = response_root.find('.//answerhashes')
                if answer_hashes is not None:
                    for ans in answer_hashes:
                        name = ans.tag
                        answer_inputs = stg.find(".//*[@name='%s']" % (name))
                        if answer_inputs is not None:
                            correct_ans = ans.get('correct_ans','')
                            correct_ans_latex_string = ans.get('correct_ans_latex_string','')
                            if (correct_ans != '' or correct_ans_latex_string != ''):
                                answer = ET.SubElement(stage,'answer')
                                answer.text = "\n          "
                                p = ET.SubElement(answer,'p')
                                if correct_ans_latex_string:
                                    m = ET.SubElement(p, 'm')
                                    m.text = correct_ans_latex_string
                                elif correct_ans:
                                    p.text = correct_ans
                                p.tail = "\n        "
                                answer.tail = "\n        "

                solutions = stg.findall('.//solution')
                for sol in list(solutions):
                    solcopy = copy.deepcopy(sol)
                    for elem in solcopy.getiterator():
                        try:
                            elem.text = elem.text.replace("\n","\n          ")
                        except AttributeError:
                            pass
                        try:
                            elem.tail = elem.tail.replace("\n","\n          ")
                        except AttributeError:
                            pass

                    last = solcopy.xpath('./*[last()]')
                    if last:
                        last[0].tail = "\n        "
                    else:
                        print('PTX:WARNING: a solution in {} has no content'.format(problem_identifier))
                    solcopy.text = "\n          "
                    solcopy.tail = "\n        "

                    stage.append(solcopy)

                last = stage.xpath('./*[last()]')
                last[0].tail = "\n      "
                stage.tail = "\n      "

        last = static.xpath('./*[last()]')
        if last:
            last[0].tail = "\n    "
        else:
            print('PTX:WARNING: {} has no content'.format(problem_identifier))
        static.tail = "\n    "

        # Add elements for interactivity
        if (ww_reps_version == '2'):
            # Add server-data element with attribute data for rendering a problem
            source_key = 'problemSource' if (badness or origin[problem] == 'ptx') else 'sourceFilePath'
            if badness:
                source_value = badness_base64
            else:
                if origin[problem] == 'server':
                    source_value = source[problem]
                else:
                    source_value = pgbase64

            server_data = ET.SubElement(webwork_reps,'server-data')
            server_data.set(source_key,source_value)
            server_data.set('domain',ww_domain)
            server_data.set('course-id',courseID)
            server_data.set('user-id',userID)
            server_data.set('course-password',course_password)
            server_data.tail = "\n    "

        elif (ww_reps_version == '1'):
            # Add server-url elements for putting into the @src of an iframe
            for hint in ['yes','no']:
                for solution in ['yes','no']:
                    hintsol = 'hint_' + hint + '_solution_' + solution
                    source_selector = 'problemSource=' if (badness or origin[problem] == 'ptx') else 'sourceFilePath='
                    if badness:
                        source_value = urllib.parse.quote(badness_base64)
                    else:
                        if origin[problem] == 'server':
                            source_value = source[problem]
                        else:
                            source_value = urllib.parse.quote_plus(pgbase64[hintsol])
                    source_query = source_selector + source_value

                    server_url = ET.SubElement(webwork_reps,'server-url')
                    server_url.set('hint',hint)
                    server_url.set('solution',solution)
                    server_url.set('domain',ww_domain)
                    url_shell = "{}?courseID={}&amp;userID={}&amp;password={}&amp;course_password={}&amp;answersSubmitted=0&amp;displayMode=MathJax&amp;outputformat=simple&amp;problemSeed={}&amp;{}"
                    server_url.text = url_shell.format(ww_domain_path,courseID,userID,password,course_password,seed[problem],source_query)
                    server_url.tail = "\n    "

        # Add PG for PTX-authored problems
        # Empty tag with @source for server problems
        pg = ET.SubElement(webwork_reps,'pg')
        if origin[problem] == 'ptx':
            if badness:
                pg_shell = "DOCUMENT();\nloadMacros('PGstandard.pl','PGML.pl','PGcourse.pl');\nTEXT(beginproblem());\nBEGIN_PGML\n{}END_PGML\nENDDOCUMENT();"
                formatted_pg = pg_shell.format(badness_msg.format(problem_identifier, seed[problem], badness_tip))
            else:
                formatted_pg = pghuman[problem]
            # opportunity to cut out extra blank lines
            formatted_pg = re.sub(re.compile(r"(\n *\n)( *\n)*", re.MULTILINE),r"\n\n",formatted_pg)
            pg.text = ET.CDATA("\n" + formatted_pg)
        elif origin[problem] == 'server':
            pg.set('source',source[problem])
        pg.tail = "\n    "

        last = webwork_reps.xpath('./*[last()]')
        last[0].tail = "\n  "

    last = webwork_representations.xpath('./*[last()]')
    last[0].tail = "\n "

    # write to file
    include_file_name = os.path.join(dest_dir, "webwork-representations.ptx")
    try:
        with open(include_file_name, 'wb') as include_file:
            include_file.write( ET.tostring(webwork_representations, encoding="utf-8", xml_declaration=True) )
    except Exception as e:
        root_cause = str(e)
        msg = "PTX:ERROR: there was a problem writing a problem to the file: {}\n"
        raise ValueError(msg.format(include_file_name) + root_cause)

    #close session to avoid resource wanrnings
    session.close()


##############################
#
#  You Tube thumbnail scraping
#
##############################

def youtube_thumbnail(xml_source, pub_file, stringparams, xmlid_root, dest_dir):
    import os.path  # join()
    import subprocess, shutil
    import requests

    _verbose('downloading YouTube thumbnails from {} for placement in {}'.format(xml_source, dest_dir))
    ptx_xsl_dir = get_ptx_xsl_path()
    extraction_xslt = os.path.join(ptx_xsl_dir, 'extract-youtube.xsl')
    # support publisher file, subtree argument
    if pub_file:
        stringparams['publisher'] = pub_file
    if xmlid_root:
        stringparams['subtree'] = xmlid_root
    # Build list of id's into a scratch directory/file
    tmp_dir = get_temporary_directory()
    id_filename = os.path.join(tmp_dir, 'youtube-ids.txt')
    _debug('YouTube id list temporarily in {}'.format(id_filename))
    xsltproc(extraction_xslt, xml_source, id_filename, None, stringparams)
    # "run" an assignment for the list of triples of strings
    id_file = open(id_filename, 'r')
    thumb_list = id_file.readline()
    thumbs = eval(thumb_list)

    for thumb in thumbs:
        url = 'http://i.ytimg.com/vi/{}/default.jpg'.format(thumb[0])
        path = os.path.join(dest_dir, thumb[1] + '.jpg')
        _verbose('downloading {} as {}...'.format(url, path))
        # http://stackoverflow.com/questions/13137817/how-to-download-image-using-requests/13137873
        # removed some settings wrapper from around the URL, otherwise verbatim
        r = requests.get(url, stream=True)
        if r.status_code == 200:
            with open(path, 'wb') as f:
                r.raw.decode_content = True
                shutil.copyfileobj(r.raw, f)
        else:
            msg = 'PTX:ERROR: download returned a bad status code ({}), perhaps try {} manually?'
            raise OSError(msg.format(r.status_code, url))
    _verbose('YouTube thumbnail download complete')


#####################################
#
#  Interactive preview screenshotting
#
#####################################

def preview_images(xml_source, pub_file, stringparams, xmlid_root, dest_dir):
    import subprocess, shutil
    import os  # chdir
    import os.path # join()

    suffix = 'png'

    _verbose('creating interactive previews from {} for placement in {}'.format(xml_source, dest_dir))

    ptx_xsl_dir = get_ptx_xsl_path()
    extraction_xslt = os.path.join(ptx_xsl_dir, 'extract-interactive.xsl')
    # support publisher file, subtree argument
    if pub_file:
        stringparams['publisher'] = pub_file
    if xmlid_root:
        stringparams['subtree'] = xmlid_root
    # Build list of id's into a scratch directory/file
    tmp_dir = get_temporary_directory()
    id_filename = os.path.join(tmp_dir, 'interactives-ids.txt')
    _debug('Interactives id list temporarily in {}'.format(id_filename))
    xsltproc(extraction_xslt, xml_source, id_filename, None, stringparams)

    # "run" an assignment for the list of problem numbers
    id_file = open(id_filename, 'r')
    interactive_list = id_file.readline()
    interactives = eval(interactive_list)

    # Cheating a bit, base URL is *always* first item
    # Presumed to not have a trailing slash
    # Once this is a publisher option, then the xsltproc
    # call will need to accept the override as a stringparam
    baseurl = interactives[0]

    pageres_executable_cmd = get_executable_cmd('pageres')
    # TODO why this debug line? get_executable_cmd() outputs the same debug info
    _debug("pageres executable: {}".format(pageres_executable_cmd[0]))
    _debug("interactives identifiers: {}".format(interactives))

    # pageres-cli writes into current working directory
    # so change to temporary directory, and copy out
    owd = os.getcwd()
    os.chdir(tmp_dir)

    # Start after the leading base URL sneakiness
    for preview in interactives[1:]:
        input_page = os.path.join(baseurl, preview + '.html')
        page_with_fragment = ''.join([input_page, '#', preview])
        selector_option = '--selector=#' + preview
        # file suffix is provided by pageres
        format_option = '--format=' + suffix
        filename_option = '--filename=' + preview + '-preview'
        filename = preview + '-preview.' + suffix
        page_with_fragment = ''.join([input_page, '#', preview])
        _verbose('converting {} to {}'.format(page_with_fragment, filename))

        # pageres invocation
        # Overwriting files prevents numbered versions (with spaces!)
        # 3-second delay allows Javascript, etc to settle down
        # --transparent, --crop do not seem very effective
        cmd = pageres_executable_cmd + [
        "-v",
        "--overwrite",
        '-d5',
        '--transparent',
        selector_option,
        filename_option,
        input_page
        ]

        _debug("pageres command: {}".format(cmd))

        subprocess.call(cmd)
        shutil.copy2(filename, dest_dir)

    # restore working directory
    os.chdir(owd)


############
# All Images
############

def all_images(xml, pub_file, stringparams, xmlid_root):
    """All images, in all necessary formats, in subdirectories, for production of any project"""
    import os  # mkdir()
    import os.path  # join(), isdir()
    import lxml.etree as ET

    # parse source, no harm to assume
    # xinclude modularization is necessary
    src_tree = ET.parse(xml)
    src_tree.xinclude()

    # explore source for various PreTeXt elements needing assistance
    # no element => empty list => boolean is False
    has_latex_image = bool(src_tree.xpath("/pretext/*[not(docinfo)]//latex-image"))
    has_asymptote = bool(src_tree.xpath("/pretext/*[not(docinfo)]//asymptote"))
    has_sageplot = bool(src_tree.xpath("/pretext/*[not(docinfo)]//sageplot"))
    has_youtube = bool(src_tree.xpath("/pretext/*[not(docinfo)]//video[@youtube]"))
    has_preview = bool(src_tree.xpath("/pretext/*[not(docinfo)]//interactive[not(@preview)]"))

    # debugging comment/uncomment or True/False
    # has_latex_image = False
    # has_asymptote = False
    # has_sageplot = False
    # has_youtube = False
    # has_preview = False

    # get the target output directory from the publisher file
    # this is *required* so fail if pieces are missing
    if not(pub_file):
        msg = ' '.join(["creating all images requires a directory specification",
                        "in a publisher file, and no publisher file has been given"])
        raise ValueError(msg)
    generated_dir, data_dir, _ = get_image_directories(xml, pub_file)
    # correct attribute and not a directory gets caught earlier
    # but could have publisher file and bad elements/attributes
    if not(generated_dir):
        msg = ' '.join(["creating all images requires a directory specified in the",
                        "publisher file in the attribute /publication/source/@generated-images" ])
        raise ValueError(msg)

    # first stanza has code comments, and subsequent follow this
    # model so only comments are for important distinctions

    # latex-image
    #
    if has_latex_image:
        # empty last part implies directory separator
        dest_dir = os.path.join(generated_dir, 'latex-image', '')
        # make directory if not already present
        if not(os.path.isdir(dest_dir)):
            os.mkdir(dest_dir)
        latex_image_conversion(xml, pub_file, stringparams, xmlid_root, data_dir, dest_dir, 'pdf')
        latex_image_conversion(xml, pub_file, stringparams, xmlid_root, data_dir, dest_dir, 'svg')

    # Asymptote
    #
    if has_asymptote:
        dest_dir = os.path.join(generated_dir, 'asymptote', '')
        if not(os.path.isdir(dest_dir)):
            os.mkdir(dest_dir)
        asymptote_conversion(xml, pub_file, stringparams, xmlid_root, dest_dir, 'pdf')
        asymptote_conversion(xml, pub_file, stringparams, xmlid_root, dest_dir, 'html')

    # Sage plots
    #
    if has_sageplot:
        dest_dir = os.path.join(generated_dir, 'sageplot', '')
        if not(os.path.isdir(dest_dir)):
            os.mkdir(dest_dir)
        # for 3D images might produce a single PNG instead of an SVG and a PDF
        # conversions look for this PNG as a fallback absent SVG or PDF
        sage_conversion(xml, pub_file, stringparams, xmlid_root, dest_dir, 'pdf')
        sage_conversion(xml, pub_file, stringparams, xmlid_root, dest_dir, 'svg')

    # YouTube previews
    #
    if has_youtube:
        dest_dir = os.path.join(generated_dir, 'youtube', '')
        if not(os.path.isdir(dest_dir)):
            os.mkdir(dest_dir)
        # no format, they are what they are (*.jpg)
        youtube_thumbnail(xml, pub_file, stringparams, xmlid_root, dest_dir)

    # Previews (headless screenshots)
    #
    if has_preview:
        dest_dir = os.path.join(generated_dir, 'preview', '')
        if not(os.path.isdir(dest_dir)):
            os.mkdir(dest_dir)
        # no format, they are what they are (*.png)
        preview_images(xml, pub_file, stringparams, xmlid_root, dest_dir)


#####################################
#
#  MyOpenMath static problem scraping
#
#####################################

def mom_static_problems(xml_source, pub_file, stringparams, xmlid_root, dest_dir):
    import os.path # join()
    import subprocess, shutil
    import requests

    _verbose('downloading MyOpenMath static problems from {} for placement in {}'.format(xml_source, dest_dir))
    ptx_xsl_dir = get_ptx_xsl_path()
    extraction_xslt = os.path.join(ptx_xsl_dir, 'extract-mom.xsl')
    # support publisher file, subtree argument
    if pub_file:
        stringparams['publisher'] = pub_file
    if xmlid_root:
        stringparams['subtree'] = xmlid_root
    # Build list of id's into a scratch directory/file
    tmp_dir = get_temporary_directory()
    id_filename = os.path.join(tmp_dir, 'mom-ids.txt')
    _debug('MyOpenMath id list temporarily in {}'.format(id_filename))
    xsltproc(extraction_xslt, xml_source, id_filename, None, stringparams)
    # "run" an assignment for the list of problem numbers
    id_file = open(id_filename, 'r')
    problem_list = id_file.readline()
    problems = eval(problem_list)
    xml_header = '<?xml version="1.0" encoding="UTF-8" ?>\n'
    for problem in problems:
        url = 'https://www.myopenmath.com/util/mbx.php?id={}'.format(problem)
        path = os.path.join(dest_dir, 'mom-{}.xml'.format(problem))
        _verbose('downloading MOM #{} to {}...'.format(problem, path))
        # http://stackoverflow.com/questions/13137817/how-to-download-image-using-requests/13137873
        # removed some settings wrapper from around the URL, otherwise verbatim
        r = requests.get(url, stream=True)
        with open(path, 'wb') as f:
            f.write(xml_header.encode('utf-8'))
            if r.status_code == 200:
                r.raw.decode_content = True
                shutil.copyfileobj(r.raw, f)
            else:
                msg = 'PTX:ERROR: download returned a bad status code ({}), perhaps try {} manually?'
                raise OSError(msg.format(r.status_code, url))
    _verbose('MyOpenMath static problem download complete')

#######################
# Conversion to Braille
#######################

def braille(xml_source, pub_file, stringparams, out_file, dest_dir, page_format):
    """Produce a complete document in BRF format ( = Braille ASCII, plus formatting control)"""
    import os.path # join()
    import subprocess # run()

    # general message for this entire procedure
    _verbose('converting {} into BRF in {} combining UEB2 and Nemeth'.format(xml_source, dest_dir))

    # Build into a scratch directory
    tmp_dir = get_temporary_directory()
    _debug('Braille manufacture in temporary directory: {}'.format(tmp_dir))

    # use of  math_format is for consistency
    # with MathJax used to make EPUB
    math_format = 'nemeth'
    math_representations = os.path.join(tmp_dir, 'math-representations-{}.xml'.format(math_format))
    braille_xslt = os.path.join(get_ptx_xsl_path(), 'pretext-braille.xsl')
    #  liblouis-precursor.xml  is hard-coded in  pretext-braille.xsl  stylesheet
    liblouis_xml = os.path.join(tmp_dir, 'liblouis-precursor.xml')

    # ripping out LaTeX as math representations
    msg = 'converting raw LaTeX from {} into clean {} format placed into {}'
    _debug(msg.format(xml_source, math_format, math_representations))
    mathjax_latex(xml_source, pub_file, math_representations, None, math_format)

    msg = 'converting source ({}) and clean representations ({}) into liblouis precursor XML file ({})'
    _debug(msg.format(xml_source, math_representations, liblouis_xml))
    stringparams['mathfile'] = math_representations
    if pub_file:
        stringparams['publisher'] = pub_file
    xsltproc(braille_xslt, xml_source, None, tmp_dir, stringparams)

    # Main configuration file, two page format files
    liblouis_cfg = os.path.join(get_ptx_path(), 'script', 'braille', 'pretext-liblouis.cfg')
    liblouis_emboss_cfg = os.path.join(get_ptx_path(), 'script', 'braille', 'pretext-liblouis-emboss.cfg')
    liblouis_electronic_cfg = os.path.join(get_ptx_path(), 'script', 'braille', 'pretext-liblouis-electronic.cfg')
    # comma-separated configuration files, with no space
    # so as to not confuse the command construction
    if page_format == 'emboss':
        cfg = liblouis_cfg + ',' + liblouis_emboss_cfg
    elif page_format == 'electronic':
        cfg = liblouis_cfg + ',' + liblouis_electronic_cfg
    else:
        raise ValueError('PTX:BUG: braille page format not recognized')
    final_brf = get_output_filename(xml_source, out_file, dest_dir, '.brf')
    liblouis_exec_cmd = get_executable_cmd('liblouis')
    msg = 'applying liblouis to {} with configurations {}, creating BRF {}'
    _debug(msg.format(liblouis_xml, cfg, final_brf))
    liblouis_cmd = liblouis_exec_cmd + ['-f', cfg, liblouis_xml, final_brf]

    subprocess.run(liblouis_cmd)
    _verbose('BRF file deposited as {}'.format(final_brf))


####################
# Conversion to EPUB
####################

def epub(xml_source, pub_file, out_file, dest_dir, math_format):
    """Produce complete document in an EPUB container"""
    # math_format is a string that parameterizes this process
    #   'svg': mathematics as SVG
    #   'mml': mathematics as MathML
    import os, os.path, subprocess, shutil
    import re, fileinput
    import zipfile as ZIP
    import lxml.etree as ET

    # general message for this entire procedure
    _verbose('converting {} into EPUB in {} with math as {}'.format(xml_source, dest_dir, math_format))

    # Build into a scratch directory
    tmp_dir = get_temporary_directory()
    _debug('EPUB manufacture in temporary directory: {}'.format(tmp_dir))

    # Before making a zip file, the temporary directory should look
    # like the unzipped version of an EPUB file.  For us, that goes:

    # mimetype
    # EPUB
    #   package.opf
    #   css
    #   xhtml
    #     images (customizable)
    # META-INF

    source_dir = get_source_path(xml_source)
    epub_xslt = os.path.join(get_ptx_xsl_path(), 'pretext-epub.xsl')
    math_representations = os.path.join(tmp_dir, 'math-representations-{}.xml'.format(math_format))
    packaging_file = os.path.join(tmp_dir, 'packaging.xml')
    xhtml_dir = os.path.join(tmp_dir, 'EPUB', 'xhtml')

    # ripping out LaTeX as math representations
    msg = 'converting raw LaTeX from {} into clean {} format placed into {}'
    _debug(msg.format(xml_source, math_format, math_representations))
    mathjax_latex(xml_source, pub_file, math_representations, None, math_format)

    # Build necessary content and infrastructure EPUB files,
    # using SVG images of math.  Most output goes into the
    # EPUB/xhtml directory via exsl:document templates in
    # the EPUB XSL conversion.  The stylesheet does record,
    # and produce some information needed for the packaging here.
    _verbose('converting source ({}) and clean representations ({}) into EPUB files'.format(xml_source, math_representations))
    params = {}
    params['mathfile'] = math_representations
    params['math.format'] = math_format
    if pub_file:
        params['publisher'] = pub_file
    xsltproc(epub_xslt, xml_source, packaging_file, tmp_dir, params)

    # XHTML files lack an overall namespace,
    # while EPUB validation expects it
    # regex inplace to end up with:
    # <html xmlns="http://www.w3.org/1999/xhtml">
    orig = '<html'
    repl = '<html xmlns="http://www.w3.org/1999/xhtml"'
    # the inoplace facility of the fileinput module gets
    # confused about temporary backup files if the working
    # directory is not where the file lives
    # Also, print() here actual writes on the file, as
    # another facility of the fileinput module, but we need
    # to kill the "extra" newline that print() creates
    owd = os.getcwd()
    os.chdir(xhtml_dir)
    html_elt = re.compile(orig)
    for root, dirs, files in os.walk(xhtml_dir):
        for fn in files:
            for line in fileinput.input(fn, inplace=1):
                print(html_elt.sub(repl, line), end='')
    os.chdir(owd)

    # EPUB stylesheet writes an XHTML file with
    # bits of info necessary for packaging
    packaging_tree = ET.parse(packaging_file)

    # Stage CSS files in EPUB/css, coordinate
    # with names in manifest and *.xhtml via XSL.
    # CSS files live in distribution in "css" directory,
    # which is a peer of the "xsl" directory
    # EPUB exists from above xsltproc call
    css_dir = os.path.join(tmp_dir, 'EPUB', 'css')
    os.mkdir(css_dir)
    stylefile = packaging_tree.xpath('/packaging/css/@stylefile')[0]
    colorfile = packaging_tree.xpath('/packaging/css/@colorfile')[0]
    for cssfilename in [str(stylefile), str(colorfile), 'pretext_add_on.css', 'setcolors.css']:
        css = os.path.join(get_ptx_xsl_path(), '..', 'css', cssfilename)
        shutil.copy2(css, css_dir)

    # directory of images, relative to master source file, given by publisher
    # build the same directory relative to the XHTML files
    #imdir = packaging_tree.xpath('/packaging/images/@image-directory')[0]
    #source_image_dir = os.path.join(source_dir, str(imdir))
    #os.mkdir(os.path.join(tmp_dir, 'EPUB', 'xhtml', str(imdir)))
    source_image_dir = os.path.join(source_dir, 'images')
    os.mkdir(os.path.join(tmp_dir, 'EPUB', 'xhtml', 'images'))
    # position cover file
    cov = packaging_tree.xpath('/packaging/cover/@filename')[0]
    cover_source = os.path.join(source_dir, str(cov))
    cover_dest = os.path.join(tmp_dir, 'EPUB', 'xhtml', str(cov))
    shutil.copy2(cover_source, cover_dest)
    # position image files
    images = packaging_tree.xpath('/packaging/images/image/@filename')
    for im in images:
        source = os.path.join(source_dir, str(im))
        dest = os.path.join(tmp_dir, 'EPUB', 'xhtml', str(im))
        shutil.copy2(source, dest)

    # clean-up the trash
    # TODO: squelch knowls or find alternative
    # shutil.rmtree(os.path.join(tmp_dir, 'knowl'))
    # os.remove(packaging_file)
    # os.remove(math_representations)


    # mimetype parameters: -0Xq
    # -0 no compression
    # -X no extra fields, eg uid/gid on Unix
    # -q quiet (not relevant)

    # remainder parameters: -Xr9Dq
    # -X no extra fields, eg uid/gid on Unix
    # -r recursive travel
    # -9 maximum compression
    # -D no directory entries
    # -q quiet (not relevant)

    # https://www.w3.org/publishing/epub3/epub-ocf.html#sec-container-zip
    # Spec says only "deflated compression"

    # recursize walking
    # https://www.tutorialspoint.com/How-to-zip-a-folder-recursively-using-Python

    # Python 3.7 - compress level 0 to 9

    title_file_element = packaging_tree.xpath('/packaging/filename')[0]
    title_file = ET.tostring(title_file_element, method="text").decode('ascii')
    epub_file = '{}-{}.epub'.format(title_file, math_format)
    _verbose('packaging an EPUB temporarily as {}'.format(epub_file))
    owd = os.getcwd()
    os.chdir(tmp_dir)
    with ZIP.ZipFile(epub_file, mode='w', compression=ZIP.ZIP_DEFLATED) as epub:
        epub.write('mimetype', compress_type=ZIP.ZIP_STORED)
        for root, dirs, files in os.walk('EPUB'):
            for name in files:
                epub.write(os.path.join(root, name))
        for root, dirs, files in os.walk('META-INF'):
            for name in files:
                epub.write(os.path.join(root, name))
        for root, dirs, files in os.walk('css'):
            for name in files:
                epub.write(os.path.join(root, name))
    derivedname = get_output_filename(xml_source, out_file, dest_dir, '.epub')
    _verbose('EPUB file deposited as {}'.format(derivedname))
    shutil.copy2(epub_file, derivedname)
    os.chdir(owd)


####################
# Conversion to HTML
####################

def html(xml, pub_file, stringparams, dest_dir):
    """Convert XML source to HTML files in destination directory"""
    import os.path # join()

    # support publisher file, not subtree argument
    if pub_file:
        stringparams['publisher'] = pub_file
    extraction_xslt = os.path.join(get_ptx_xsl_path(), 'pretext-html.xsl')
    # Write output into working directory, no scratch space needed
    _verbose('converting {} to HTML in {}'.format(xml, dest_dir))
    xsltproc(extraction_xslt, xml, None, dest_dir, stringparams)


#####################
# Conversion to LaTeX
#####################

def latex(xml, pub_file, stringparams, out_file, dest_dir):
    """Convert XML source to LateX and then a PDF in destination directory"""
    import os.path # join()

    # support publisher file, not subtree argument
    if pub_file:
        stringparams['publisher'] = pub_file
    extraction_xslt = os.path.join(get_ptx_xsl_path(), 'pretext-latex.xsl')
    # form output filename based on source filename
    derivedname = get_output_filename(xml, out_file, dest_dir, '.tex')
    # Write output into working directory, no scratch space needed
    _verbose('converting {} to LaTeX as {}'.format(xml, derivedname))
    xsltproc(extraction_xslt, xml, derivedname, None, stringparams)


#################
# XSLT Processing
#################

# Pythonic replacement for xsltproc executable
def xsltproc(xsl, xml, result, output_dir=None, stringparams={}):
    """
    Apply an XSL stylesheet to an XML source, with control over location of results.

    xsl          - filename (string) for XSL stylesheet
    xml          - filename (string) for XML source
    result       - filename (string) for result tree of the stylesheet
                   None if stylesheet 100% writes its own files,
                   i.e. expecting an empty result tree
    output_dir   - a directory for exsl:document() templates to write to
    stringparams - a dictionary of option/value string:string pairs to
                   pass to  xsl:param  elements of the stylesheet

    N.B. The value of a "publisher" string parameter passed in the
    "stringparams" argument must be a complete path, since a relative
    path can be rendered incorrect by the change to an "output_dir"
    different than that at the time of the command-line invocation.
    """
    import os
    import lxml.etree as ET
    import subprocess

    _verbose('XSL conversion of {} by {}'.format(xml, xsl))
    debug_string = 'XSL conversion via {} of {} to {} and/or into directory {} with parameters {}'
    _debug(debug_string.format(xsl, xml, result, output_dir, stringparams))

    # add git describe to stringparams
    if (get_ptx_git_path()):
        stringparams['git.describe'] = subprocess.check_output(['git', '--git-dir=' + get_ptx_git_path(), 'describe']).strip()

    # string parameters arrive in a "plain" string:string dictionary
    # but the values need to be prepped for lxml use, always
    stringparams = {key:ET.XSLT.strparam(value) for (key, value) in stringparams.items()}

    # parse source, no harm to assume
    # xinclude modularization is necessary
    src_tree = ET.parse(xml)
    src_tree.xinclude()

    # parse xsl, and build a transformation object
    # allow writing if an output directory is given
    # this is the default, but we are explicit here
    control = None
    if output_dir:
        control = ET.XSLTAccessControl(write_file=True)
    xsl_tree = ET.parse(xsl)
    xslt = ET.XSLT(xsl_tree, access_control=control)

    # do the transformation, with parameterization
    # possibly change/restore directories to capture
    # (multi-)file output from  exsl:document() calls
    owd = os.getcwd()
    if output_dir:
        os.chdir(output_dir)
    # clear global errors, apply the xsl transform
    ET.clear_error_log()
    result_tree = xslt(src_tree, **stringparams)
    # report any errors
    messages = xslt.error_log
    if messages:
        print('Messages from application of {}:'.format(xsl))
        for m in messages:
            print(m.message)
    os.chdir(owd)

    # write a serialized version to a file if
    # there is a non-empty result tree on stdout
    # NB: this seems to presume an ASCII (not UTF-8)
    # encoding for output, no matter what stylesheet says
    # There seems to be a way to set this, but that would
    # possibly be a significant change in behavior, so
    # should be extensively tested
    if result:
        with open(result, 'w') as result_file:
            result_file.write(str(result_tree))


###################
#
# Utility Functions
#
###################

def set_verbosity(v):
    """Set how chatty routines are at console: 0, 1, or 2"""
    # 0 - nothing
    # 1 - _verbose() only
    # 2 - _verbose() and _debug()
    global _verbosity

    if ((v != 0) and (v !=1 ) and (v!= 2)):
        raise ValueError('PTX:ERROR: verbosity level is 0, 1, or 2, not {}'.format(v))
    _verbosity = v

def _verbose(msg):
    """Write a message to the console on program progress"""
    if _verbosity >= 1:
        print('PTX: {}'.format(msg))

def _debug(msg):
    """Write a message to the console with some raw information"""
    if _verbosity >= 2:
        print('PTX:DEBUG: {}'.format(msg))

def python_version():
    """Return 'major.minor' version number as string/info"""
    import sys

    return '{}.{}'.format(sys.version_info[0], sys.version_info[1])

def check_python_version():
    """Raise error with Python 2 (or less)"""
    import sys # version_info

    # This test could be more precise,
    # but only handling 2to3 switch when introduced
    msg = ''.join(["PreTeXt script/module expects Python 3.4, not Python 2 or older\n",
                   "You have Python {}\n",
                   "** Try prefixing your command-line with 'python3 ' **"])
    if sys.version_info[0] <= 2:
        raise(OSError(msg.format(python_version())))

def set_ptx_path():
    """Discover and set path to root of PreTeXt distribution"""
    # necessary to locate configuration files, XSL stylesheets
    # since authors can drop distribution *anywhere* in their system
    global _ptx_path
    import os.path # abspath(), split()

    # full path to module itself
    ptx_path = os.path.abspath(__file__)
    # split "python.py" off module's filename
    module_dir, _ = os.path.split(ptx_path)
    # split "pretext" path off executable
    _ptx_path, _ = os.path.split(module_dir)
    return None

def get_ptx_path():
    """Returns path to root of PreTeXt distribution"""
    global _ptx_path

    return _ptx_path

def get_ptx_xsl_path():
    """Returns path of PreTeXt XSL directory"""
    import os.path

    return os.path.join(get_ptx_path(), 'xsl')

def get_ptx_git_path():
    """Returns path of PreTeXt .git directory"""
    import os.path
    from os import path

    ptx_git_path = os.path.join(get_ptx_path(), '.git')
    if path.exists(ptx_git_path):
        return ptx_git_path
    else:
        return None

def get_source_path(source_file):
    """Returns path of source XML file"""
    import sys, os.path

    # split path off filename
    source_dir, _ = os.path.split(source_file)
    _verbose("discovering source file's directory name: {}".format(source_dir))
    return os.path.normpath(source_dir)

def get_executable_cmd(exec_name):
    """Queries configuration file for executable name, verifies existence in Unix"""
    import os
    import platform
    import subprocess
    import shutil # .which()

    # parse user configuration(s), contains locations of executables
    # in the "executables" section of the INI-style file
    config = get_config_info()

    # get the name, but then see if it really, really works
    _debug('locating "{}" in [executables] section of configuration file'.format(exec_name))
    config_cmd_line = config.get('executables', exec_name).split()

    # Returns the full-path version of the command, as if the PATH was employed
    # "None" indicates the executable does not exist on the system
    # https://stackoverflow.com/questions/377017/test-if-executable-exists-in-python
    normalized_exec = shutil.which(config_cmd_line[0])

    error_messages = []
    if normalized_exec == None:
        error_messages += [
            'PTX:ERROR: cannot locate executable with configuration name `{}` as command `{}`'.format(exec_name, config_cmd_line[0]),
            '*** Edit the configuration file and/or install the necessary program ***'
        ]
    if config_cmd_line[0] == "pdfcrop":
        error_messages += [
            'PTX:ERROR: Program "pdfcrop" was replaced by "pdf-crop-margins" as of 2020-07-07.',
            'Install with "pip install pdfCropMargins" and update your configuration file with "pdfcrop = pdf-crop-margins".'
        ]
    if error_messages:
        raise OSError('\n'.join(error_messages))
    _debug("{} executable: {}, options: {}".format(exec_name, config_cmd_line[0], ' '.join(config_cmd_line[1:])))
    return config_cmd_line

def sanitize_url(url):
    """Verify a server address"""
    _verbose('validating, cleaning server URL: {}'.format(url))
    import requests
    try:
        requests.get(url)
    except requests.exceptions.RequestException as e:
        root_cause = str(e)
        msg = "PTX:ERROR: there was a problem with the server URL, {}\n".format(url)
        raise ValueError(msg + root_cause)
    return url

def sanitize_alpha_num_underscore(param):
    """Verify parameter is a string containing only alphanumeric and undescores"""
    import string
    allowed = set(string.ascii_letters + string.digits + '_')
    _verbose('verifying parameter: {}'.format(param))
    if not(set(param) <= allowed):
        raise ValueError('PTX:ERROR: param {} contains characters other than a-zA-Z0-9_ '.format(param))
    return param

def set_config_info():
    """Create configuation in object for querying"""
    global _config
    import os.path # join()
    import configparser # ConfigParser()

    ptx_dir = get_ptx_path()
    config_filename = 'pretext.cfg'
    default_config_file = os.path.join(ptx_dir, 'pretext', config_filename)
    user_config_file = os.path.join(ptx_dir, 'user', config_filename)
    # 2020-05-21: obsolete'd mbx script and associated config filenames
    # Try to read old version, but prefer new version
    stale_user_config_file = os.path.join(ptx_dir, 'user', 'mbx.cfg')
    config_file_list = [default_config_file, stale_user_config_file, user_config_file]
    # ConfigParser module was renamed to configparser in Python 3
    # and object was renamed from SafeConfigParser() to ConfigParser()
    _config = configparser.ConfigParser()

    _verbose("parsing possible configuration files: {}".format(config_file_list))
    files_read = _config.read(config_file_list)
    _debug("configuration files actually used/read: {}".format(files_read))
    if not(user_config_file in files_read):
        msg = "using default configuration only, custom configuration file not used at {}"
        _verbose(msg.format(user_config_file))
    return _config

# def debug_config_info():

def get_config_info():
    """Return configuation in object for querying"""
    global _config

    return _config

def copy_data_directory(source_file, data_dir, tmp_dir):
    """Stage directory from CLI argument into the working directory"""
    import os.path, shutil

    # Assumes all input paths are absolute, and that
    # data_dir is one step longer than directory for source_file,
    # in other words, data directory is a peer of source file
    _verbose("formulating data directory location")
    source_full_path, _ = os.path.split(source_file)
    data_last_step = os.path.basename(data_dir)
    destination_root = os.path.join(tmp_dir, data_last_step)
    _debug("copying data directory {} to working location {}".format(data_dir, destination_root))
    shutil.copytree(data_dir, destination_root)

def get_temporary_directory():
    """Create, record, and return a scratch directory"""
    import tempfile #  mkdtemp()
    global _temps   #  cache of temporary directories

    temp_dir = tempfile.mkdtemp()
    # Register the directory for cleanup at the end of successful
    # execution iff the verbosity is set to level 2 ("debug")
    # So errors, or requesting gross debugging info, will leave the
    # directories behind for inspection, otherwise they get removed
    _temps.append(temp_dir)
    return temp_dir

def get_output_filename(xml, out_file, dest_dir, suffix):
    """Formulate a filename for single-file output"""
    #  out_file  is None, or full path
    #  dest_dir is at least current working directory
    import os.path # split(), splitext()

    if out_file:
        return out_file
    # split off source filename, replace suffix
    derivedname = os.path.splitext(os.path.split(xml)[1])[0]  + suffix
    return os.path.join(dest_dir, derivedname)

def release_temporary_directories():
    """Release scratch directories unless requesting debugging info"""
    import shutil #  rmtree()
    global _temps #  cache of temporary directories

    _debug('Temporary directories left behind for inspection: {}'.format(_temps))
    if _verbosity < 2:
        for td in _temps:
            _verbose('Removing temporary directory {}'.format(td))
            # conservatively, raise exception on errors
            shutil.rmtree(td, ignore_errors=False)

def verify_input_directory(inputdir):
    """Verify directory exists, or raise error.  Return absolute path"""
    import os.path # isdir(), abspath()

    _verbose('verifying and expanding input directory: {}'.format(inputdir))
    if not(os.path.isdir(inputdir)):
        raise ValueError('directory {} does not exist'.format(inputdir))
    absdir = os.path.abspath(inputdir)
    _verbose('input directory expanded to absolute path: {}'.format(absdir))
    return absdir

def get_image_directories(xml_source, pub_file):
    """Returns triple: (generated, data, external) absolute paths, derived from publisher file"""
    import os.path # isabs, split
    import lxml.etree as ET  # XML source

    # N.B. manage attributes carefully to distinguish
    # absent (None) versus empty string value ('')

    # Examine /publication/source element carefully for
    # attributes which we code here for convenience
    gen_attr = 'generated-images'
    data_attr = 'data-images'
    ext_attr = 'source-images'

    # prepare for relative paths later
    source_dir = get_source_path(xml_source)

    # Unknown until running the gauntlet
    generated = None
    data = None
    external = None
    if pub_file:
        # parse publisher file, xinclude is conceivable
        # for multiple similar files with common parts
        pub_tree = ET.parse(pub_file)
        pub_tree.xinclude()
        # "source" element => single-item list
        # no "source" element => empty list => triple of None returned
        element_list = pub_tree.xpath("/publication/source")
        if element_list:
            attributes_dict = element_list[0].attrib
            # attribute absent => None
            if gen_attr in attributes_dict.keys():
                raw_path = attributes_dict[gen_attr]
                if os.path.isabs(raw_path):
                    abs_path = raw_path
                else:
                    abs_path = os.path.join(source_dir, raw_path)
                generated = verify_input_directory(abs_path)
            # attribute absent => None
            if data_attr in attributes_dict.keys():
                raw_path = attributes_dict[data_attr]
                if os.path.isabs(raw_path):
                    msg = ' '.join(['the directory path to data for images, given in the',
                          'publisher file as "source/@{}" must be relative to',
                          'the PreTeXt source file location, and not the absolute path "{}"'])
                    raise ValueError(msg.format(data_attr, raw_path))
                else:
                    abs_path = os.path.join(source_dir, raw_path)
                data = verify_input_directory(abs_path)
            # attribute absent => None
            if ext_attr in attributes_dict.keys():
                raw_path = attributes_dict[ext_attr]
                if os.path.isabs(raw_path):
                    msg = ' '.join(['the directory path to source images, given in the',
                          'publisher file as "source/@{}" must be relative to',
                          'the PreTeXt source file location, and not the absolute path "{}"'])
                    raise ValueError(msg.format(ext_attr, raw_path))
                else:
                    abs_path = os.path.join(source_dir, raw_path)
                external = verify_input_directory(abs_path)
    # triple of discovered paths
    return (generated, data, external)


########
#
# Module
#
########

# One-time set-up for global use in the module
# Module provides, and depends on:
#
#  _verbosity - level of detail in console output
#
#  _ptx_path - root directory of installed PreTeXt distribution
#              necessary to locate stylesheets and other support
#
#  _config - parsed values from an INI-style configuration file

# verbosity parameter defaults to 0 at startup
# employing application can use set_verbosity()
# to override via application's methodology
_verbosity = None
set_verbosity(0)

# Discover and set distribution path once at start-up
_ptx_path = None
set_ptx_path()

# Parse configuration file once
_config = None
set_config_info()

_temps = []