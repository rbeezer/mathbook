#!/usr/bin/env python3
# ********************************************************************
# Copyright 2010-2016 Robert A. Beezer
#
# This file is part of MathBook XML.
#
# MathBook XML is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 or version 3 of the
# License (at your option).
#
# MathBook XML is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with MathBook XML.  If not, see <http://www.gnu.org/licenses/>.
# *********************************************************************

# 2016-05-05: this script should run under Python 2.7 and Python 3

# messy hack to support both `python -m script.mbx` and `./mbx.py`:
try:
    from .version import __version__
except ImportError:
    from version import __version__

##############################################
#
#  Graphics Language Extraction and Processing
#
##############################################

def tikz_conversion(xml_source, xmlid_root, dest_dir, outformat):
    global config
    import tempfile, os, os.path, subprocess, shutil
    _verbose('converting tikz pictures from {} to {} graphics for placement in {}'.format(xml_source, outformat, dest_dir))
    dest_dir = sanitize_directory(dest_dir)
    tmp_dir = tempfile.mkdtemp()
    _debug("temporary directory: {}".format(tmp_dir))
    xslt_executable = get_executable(config,  'xslt')
    _debug("xslt executable: {}".format(xslt_executable))
    tex_executable = get_executable(config,  'tex')
    _debug("tex executable: {}".format(tex_executable))
    pdfsvg_executable = get_executable(config, 'pdfsvg')
    _debug("pdfsvg executable: {}".format(pdfsvg_executable))
    # http://stackoverflow.com/questions/11269575/how-to-hide-output-of-subprocess-in-python-2-7
    devnull = open(os.devnull, 'w')
    convert_cmd = [xslt_executable,
        '--stringparam', 'scratch', tmp_dir,
        '--stringparam', 'subtree', xmlid_root,
        '--xinclude',
        os.path.join(mbx_xsl_dir, 'extract-tikz.xsl'),
        xml_source
        ]
    _verbose("extracting tikz pictures from {}".format(xml_source))
    _debug("tikz conversion {}".format(convert_cmd))
    subprocess.call(convert_cmd)
    cwd = os.getcwd()
    os.chdir(tmp_dir)
    for tikzpic in os.listdir(tmp_dir):
        if outformat == 'source':
            shutil.copy2(tikzpic, dest_dir)
        else:
            filebase, _ = os.path.splitext(tikzpic)
            tikzpdf = "{}.pdf".format(filebase)
            tikzsvg = "{}.svg".format(filebase)
            latex_cmd = [tex_executable, tikzpic]
            _verbose("converting {} to {}".format(tikzpic, tikzpdf))
            subprocess.call(latex_cmd, stdout=devnull, stderr=subprocess.STDOUT)
            if outformat == 'svg':
                svg_cmd = [pdfsvg_executable, tikzpdf, tikzsvg]
                _verbose("converting {} to {}".format(tikzpdf, tikzsvg))
                subprocess.call(svg_cmd)
                shutil.copy2(tikzsvg, dest_dir)
            if outformat == 'pdf':
                shutil.copy2(tikzpdf, dest_dir)


def asymptote_conversion(xml_source, xmlid_root, dest_dir, outformat):
    global config
    import tempfile, os, os.path, subprocess, shutil, glob
    _verbose('converting Asymptote diagrams from {} to {} graphics for placement in {}'.format(xml_source, outformat.upper(), dest_dir))
    dest_dir = sanitize_directory(dest_dir)
    tmp_dir = tempfile.mkdtemp()
    plat = get_platform()
    if plat == "Windows":
        dest_dir = break_windows_path(dest_dir)
        tmp_dir = break_windows_path(tmp_dir)
    _debug("temporary directory: {}".format(tmp_dir))
    xslt_executable = get_executable(config,  'xslt')
    _debug("xslt executable: {}".format(xslt_executable))
    asy_executable = get_executable(config,  'asy')
    _debug("asy executable: {}".format(asy_executable))
    extract_cmd = [xslt_executable,
        '--stringparam', 'scratch', tmp_dir,
        '--stringparam', 'subtree', xmlid_root,
        '--xinclude',
        os.path.join(mbx_xsl_dir, 'extract-asymptote.xsl'),
        xml_source
        ]
    # stylesheet uses variable-subtree infrastructure, so we get list
    # items, but not the list structure itself.  Easily remedied
    _verbose("extracting Asymptote diagrams from {}".format(xml_source))
    diagram_list = '[' + subprocess.check_output(extract_cmd).decode('ascii') + ']'
    diagrams = eval(diagram_list)
    cwd = os.getcwd()
    os.chdir(tmp_dir)
    devnull = open(os.devnull, 'w')
    # perhaps replace following stock advisory with a real version
    # check using the (undocumented) distutils.version module, see:
    # https://stackoverflow.com/questions/11887762/how-do-i-compare-version-numbers-in-python
    if outformat == 'html':
        # https://stackoverflow.com/questions/4514751/pipe-subprocess-standard-output-to-a-variable
        proc = subprocess.Popen([asy_executable, '--version'], stderr=subprocess.PIPE)
        asyversion = proc.stderr.read()
        _verbose("#####################################################")
        _verbose("Asymptote 3D HTML output is experimental (2020-01-24)")
        _verbose("it is only supported by Asymptote 2.62 and")
        _verbose("newer, your Asymptote executable in use reports:")
        _verbose(asyversion)
        _verbose("#####################################################")
    # every diagram should be a *.asy file in tmp_dir, which is cwd
    # we loop over the list, rather than the directory,
    # so as to have extra info, such as the target dimension
    for diagram in diagrams:
        asydiagram = diagram[0]
        # can condition processing on diagram[1]
        # which is a string: '2D' or '3D'
        if outformat == 'source':
            shutil.copy2(asydiagram, dest_dir)
        elif outformat == 'html':
            filebase, _ = os.path.splitext(asydiagram)
            asyout = "{}.{}".format(filebase, outformat)
            asysvg = "{}.svg".format(filebase)
            asypng = "{}_*.png".format(filebase)
            asy_cmd = [asy_executable, '-outformat', outformat, asydiagram]
            _verbose("converting {} to {}".format(asydiagram, asyout))
            _debug("asymptote conversion {}".format(asy_cmd))
            subprocess.call(asy_cmd, stdout=devnull, stderr=subprocess.STDOUT)
            if os.path.exists(asyout) == True:
                shutil.copy2(asyout, dest_dir)
            else:
                shutil.copy2(asysvg, dest_dir)
                # Sometimes Asymptotes SVGs include multiple PNGs for colored regions
                for f in glob.glob(asypng):
                    shutil.copy2(f, dest_dir)
        else:
            filebase, _ = os.path.splitext(asydiagram)
            asyout = "{}.{}".format(filebase, outformat)
            asypng = "{}_*.png".format(filebase)
            asy_cmd = [asy_executable, '-noprc', '-offscreen', '-batchMask', '-outformat', outformat, asydiagram]
            _verbose("converting {} to {}".format(asydiagram, asyout))
            _debug("asymptote conversion {}".format(asy_cmd))
            subprocess.call(asy_cmd, stdout=devnull, stderr=subprocess.STDOUT)
            shutil.copy2(asyout, dest_dir)
            # Sometimes Asymptotes SVGs include multiple PNGs for colored regions
            for f in glob.glob(asypng):
                shutil.copy2(f, dest_dir)


def sage_conversion(xml_source, xmlid_root, dest_dir, outformat):
    global config
    import tempfile, os, os.path, subprocess, shutil, glob
    _verbose('converting Sage diagrams from {} to {} graphics for placement in {}'.format(xml_source, outformat.upper(), dest_dir))
    dest_dir = sanitize_directory(dest_dir)
    tmp_dir = tempfile.mkdtemp()
    plat = get_platform()
    _debug("temporary directory: {}".format(tmp_dir))
    xslt_executable = get_executable(config,  'xslt')
    _debug("xslt executable: {}".format(xslt_executable))
    sage_executable = get_executable(config,  'sage')
    _debug("sage executable: {}".format(sage_executable))
    extract_cmd = [xslt_executable,
        '--stringparam', 'scratch', tmp_dir,
        '--stringparam', 'subtree', xmlid_root,
        '--xinclude',
        os.path.join(mbx_xsl_dir, 'extract-sageplot.xsl'),
        xml_source
        ]
    _verbose("extracting Sage diagrams from {}".format(xml_source))
    subprocess.call(extract_cmd)
    cwd = os.getcwd()
    os.chdir(tmp_dir)
    devnull = open(os.devnull, 'w')
    for sageplot in os.listdir(tmp_dir):
        if outformat == 'source':
            shutil.copy2(sageplot, dest_dir)
        else:
            filebase, _ = os.path.splitext(sageplot)
            sageout = "{0}.{1}".format(filebase, outformat)
            sagepng = "{0}.png".format(filebase, outformat)
            sage_cmd = [sage_executable,  sageplot, outformat]
            _verbose("converting {} to {} (or {} for 3D)".format(sageplot, sageout, sagepng))
            _debug("sage conversion {}".format(sage_cmd))
            subprocess.call(sage_cmd, stdout=devnull, stderr=subprocess.STDOUT)
            # Sage makes PNGs for 3D
            for f in glob.glob(sageout):
                shutil.copy2(f, dest_dir)
            for f in glob.glob(sagepng):
                shutil.copy2(f, dest_dir)

def latex_image_conversion(xml_source, stringparams, xmlid_root, data_dir, dest_dir, outformat):
    global config
    import tempfile, os, os.path, subprocess, shutil
    plat = get_platform()
    _verbose('converting latex-image pictures from {} to {} graphics for placement in {}'.format(xml_source, outformat, dest_dir))
    _verbose('string parameters after command line is parsed: {}'.format(stringparams))
    params = []
    if stringparams:
        # assumes pairs, could add crude check for even length
        for i in range(len(stringparams)/2):
            params.append('-stringparam')
            params.append(stringparams[2*i])
            params.append(stringparams[2*i+1])
        _verbose('options added to xsltproc extraction: {}'.format(params))
    dest_dir = sanitize_directory(dest_dir)
    tmp_dir = tempfile.mkdtemp()
    if plat == "Windows":
        tmp_dir = break_windows_path(tmp_dir)
    _debug("temporary directory: {}".format(tmp_dir))
    xslt_executable = get_executable(config,  'xslt')
    _debug("xslt executable: {}".format(xslt_executable))
    # NB: next command uses relative paths, so no chdir(), etc beforehand
    if data_dir:
        copy_data_directory(xml_source, data_dir, tmp_dir)
    # http://stackoverflow.com/questions/11269575/how-to-hide-output-of-subprocess-in-python-2-7
    devnull = open(os.devnull, 'w')
    if plat == "Windows":
        convert_cmd = [xslt_executable] + params + [
            '--stringparam', 'scratch', tmp_dir,
            '--stringparam', 'subtree', xmlid_root,
            '--xinclude',
            "/".join((mbx_xsl_dir, 'extract-latex-image.xsl')),
            # this is compatible with Windows CMD and also with Git Bash's MSYS shell
            xml_source
            ]
    else:
        convert_cmd = [xslt_executable] + params + [
            '--stringparam', 'scratch', tmp_dir,
            '--stringparam', 'subtree', xmlid_root,
            '--xinclude',
            os.path.join(mbx_xsl_dir, 'extract-latex-image.xsl'),
            xml_source
            ]
    _verbose("extracting latex-image pictures from {}".format(xml_source))
    _debug("latex-image conversion {}".format(convert_cmd))
    subprocess.call(convert_cmd)
    cwd = os.getcwd()
    os.chdir(tmp_dir)
    # files *only*, from top-level
    files = list(filter(os.path.isfile, os.listdir(tmp_dir)))
    for latex_image in files:
        if outformat == 'source':
            shutil.copy2(latex_image, dest_dir)
        else:
            filebase, _ = os.path.splitext(latex_image)
            latex_image_pdf = "{}.pdf".format(filebase)
            latex_image_svg = "{}.svg".format(filebase)
            latex_image_png = "{}.png".format(filebase)
            latex_image_eps = "{}.eps".format(filebase)
            tex_executable = get_executable(config,  'tex')
            _debug("tex executable: {}".format(tex_executable))
            latex_cmd = [tex_executable, "-interaction=batchmode", latex_image]
            _verbose("converting {} to {}".format(latex_image, latex_image_pdf))
            subprocess.call(latex_cmd, stdout=devnull, stderr=subprocess.STDOUT)
            pdfcrop_executable = get_executable(config,  'pdfcrop')
            _debug("pdfcrop executable: {}".format(pdfcrop_executable))
            if plat == "Windows":
                _debug("using pdfcrop is not reliable on Windows unless you are using a linux-like shell, e.g. Git Bash or SageMathCloud terminal")
                if is_os_64bit():
                    pdfcrop_cmd = [pdfcrop_executable, "--gscmd", "gswin64c.exe", latex_image_pdf, latex_image_pdf]
                else:
                    pdfcrop_cmd = [pdfcrop_executable, "--gscmd", "gswin32c.exe", latex_image_pdf, latex_image_pdf]
            else:
                pdfcrop_cmd = [pdfcrop_executable, latex_image_pdf, latex_image_pdf]
            _verbose("cropping {} to {}".format(latex_image_pdf, latex_image_pdf))
            subprocess.call(pdfcrop_cmd, stdout=devnull, stderr=subprocess.STDOUT)
            if outformat == 'all':
                shutil.copy2(latex_image, dest_dir)
            if (outformat == 'pdf' or outformat == 'all'):
                shutil.copy2(latex_image_pdf, dest_dir)
            if (outformat == 'svg' or outformat == 'all'):
                pdfsvg_executable = get_executable(config, 'pdfsvg')
                _debug("pdfsvg executable: {}".format(pdfsvg_executable))
                svg_cmd = [pdfsvg_executable, latex_image_pdf, latex_image_svg]
                _verbose("converting {} to {}".format(latex_image_pdf, latex_image_svg))
                subprocess.call(svg_cmd)
                shutil.copy2(latex_image_svg, dest_dir)
            if (outformat == 'png' or outformat == 'all'):
                # create high-quality png, presumes "convert" executable
                pdfpng_executable = get_executable(config, 'pdfpng')
                _debug("pdfpng executable: {}".format(pdfpng_executable))
                png_cmd = [pdfpng_executable, "-density", "300",  latex_image_pdf, "-quality", "100", latex_image_png]
                _verbose("converting {} to {}".format(latex_image_pdf, latex_image_png))
                subprocess.call(png_cmd)
                shutil.copy2(latex_image_png, dest_dir)
            if (outformat == 'eps' or outformat == 'all'):
                pdfeps_executable = get_executable(config, 'pdfeps')
                _debug("pdfeps executable: {}".format(pdfeps_executable))
                eps_cmd = [pdfeps_executable, '-eps', latex_image_pdf, latex_image_eps]
                _verbose("converting {} to {}".format(latex_image_pdf, latex_image_eps))
                subprocess.call(eps_cmd)
                shutil.copy2(latex_image_eps, dest_dir)

################################
#
#  WeBWorK Extraction Processing
#
################################

def webwork_to_xml(xslt_exec, ptx_xsl_dir, xml_source, server_params, dest_dir):
    import subprocess, os.path, xml.dom.minidom

    # base64 and url encoding depends on Python version; make Boolean here
    PY3 = sys.version_info[0] >= 3

    if PY3:
        import urllib.parse
        from urllib.parse import urlparse
    else:
        import urllib
        from urlparse import urlparse

    # at least on Mac installations, requests module is not standard
    try:
        import requests
    except ImportError:
        msg = 'failed to import requests module, is it installed?'
        raise ValueError(msg)

    import re     # regular expressions for parsing
    from xml.sax.saxutils import escape    # sanitize string

    # execute XSL extraction to get back four dictionaries
    # where the keys are the internal-ids for the problems
    # origin, seed, source, pg
    xsl_transform = 'extract-pg.xsl'
    extraction_xslt = os.path.join(ptx_xsl_dir, xsl_transform)
    cmd = [xslt_exec, '--xinclude', extraction_xslt, xml_source]
    try:
        problem_dictionaries = subprocess.check_output(cmd)
    except subprocess.CalledProcessError as e:
        root_cause = str(e)
        msg = 'xsltproc command failed, tried: "{}"\n'.format(' '.join(cmd))
        raise ValueError(msg + root_cause)

    # execute XSL extraction to get back the dictionary
    # where the keys are the internal-ids for the problems
    # pgptx
    xsl_transform_pgptx = 'extract-pg-ptx.xsl'
    extraction_xslt_pgptx = os.path.join(ptx_xsl_dir, xsl_transform_pgptx)
    cmd = [xslt_exec, '--xinclude', extraction_xslt_pgptx, xml_source]
    try:
        problem_dictionary_pgptx = subprocess.check_output(cmd)
    except subprocess.CalledProcessError as e:
        root_cause = str(e)
        msg = 'xsltproc command failed, tried: "{}"\n'.format(' '.join(cmd))
        raise ValueError(msg + root_cause)

    # "run" the dictionaries
    # protect backslashes in LaTeX code
    # globals() necessary for success in both Python 2 and 3
    exec(problem_dictionaries.decode('utf-8').replace('\\','\\\\'), globals())
    exec(problem_dictionary_pgptx.decode('utf-8').replace('\\','\\\\'), globals())

    # initialize more dictionaries
    pgbase64 = {}
    pgbase64['hint_yes_solution_yes'] = {}
    pgbase64['hint_yes_solution_no'] = {}
    pgbase64['hint_no_solution_yes'] = {}
    pgbase64['hint_no_solution_no'] = {}
    static = {}

    # verify destination exists
    sanitize_directory(dest_dir)
    if plat == "Windows":
        dest_dir = break_windows_path(dest_dir)

    # verify, construct problem format requestor
    # remove any surrounding white space
    server_params = server_params.strip()
    if (server_params.startswith("(") and server_params.endswith(")")):
        server_params=server_params.strip('()')
        split_server_params = server_params.split(',')
        server_url = sanitize_url(split_server_params[0])
        courseID = sanitize_alpha_num_underscore(split_server_params[1])
        userID = sanitize_alpha_num_underscore(split_server_params[2])
        password = sanitize_alpha_num_underscore(split_server_params[3])
        course_password = sanitize_alpha_num_underscore(split_server_params[4])
    else:
        server_url = sanitize_url(server_params)
        courseID = 'anonymous'
        userID = 'anonymous'
        password = 'anonymous'
        course_password = 'anonymous'

    wwurl = server_url + "webwork2/html2xml"

    # Begin preparation for getting static versions

    # using a "Session()" will pool connection information
    # since we always hit the same server, this should increase performance
    session = requests.Session()

    # XML content comes back
    # these delimit what we want
    start_marker = re.compile('<!--BEGIN PROBLEM-->')
    end_marker = re.compile('<!--END PROBLEM-->')

    # End preparation for getting static versions

    # begin writing single .xml file with all webwork representations
    include_file_name = os.path.join(dest_dir, "webwork-extraction.xml")
    try:
         with open(include_file_name, 'w') as include_file:
            include_file.write('<?xml version="1.0" encoding="UTF-8" ?>\n<webwork-extraction>\n')
    except Exception as e:
        root_cause = str(e)
        msg = "There was a problem writing a problem to the file: {}\n"
        raise ValueError(msg.format(include_file_name) + root_cause)

    # Choose one of the dictionaries to take its keys as what to loop through
    for problem in sorted(origin):

        # It is more convenient to identify server problems by file path,
        # and PTX problems by internal ID
        problem_identifier = problem if (origin[problem] == 'ptx') else source[problem]

        #remove outer webwork tag (and attributes) from authored source
        if origin[problem] == 'ptx':
            source[problem] = re.sub(r"<webwork.*?>",'',source[problem]).replace('</webwork>','')

        #use "webwork-reps" as parent tag for the various representations of a problem
        try:
            with open(include_file_name, 'a') as include_file:
                webwork_reps = '  <webwork-reps xml:id="extracted-{}" ww-id="{}">\n'
                include_file.write(webwork_reps.format(problem,problem))
        except Exception as e:
            root_cause = str(e)
            msg = "There was a problem writing a problem to the file: {}\n"
            raise ValueError(msg.format(include_file_name) + root_cause)

        if origin[problem] == 'server':
            msg = 'writing representations of server-based WeBWorK problem'
        elif origin[problem] == 'ptx':
            msg = 'writing representations of PTX-authored WeBWorK problem'
        else:
            raise ValueError("problem origin should be 'server' or 'ptx', not '{}'".format(origin[problem]))
        _verbose(msg)

        # make base64 for PTX problems
        if origin[problem] == 'ptx':
            for hint_sol in ['hint_yes_solution_yes','hint_yes_solution_no','hint_no_solution_yes','hint_no_solution_no']:
                if PY3:
                    import base64
                    pgbase64[hint_sol][problem] = base64.b64encode(bytes(pgptx[hint_sol][problem], 'utf-8'))
                else:
                    pgbase64[hint_sol][problem] = pgptx[hint_sol][problem].encode('base64').replace('\n', '')

        # First write authored
        if origin[problem] == 'ptx':
            try:
                with open(include_file_name, 'a') as include_file:
                    authored_tag = '    <authored>\n{}\n    </authored>\n\n'
                    include_file.write(authored_tag.format(re.sub(re.compile('^(?=.)', re.MULTILINE),'      ',source[problem])))
            except Exception as e:
                root_cause = str(e)
                msg = "There was a problem writing the authored source of {} to the file: {}\n"
                raise ValueError(msg.format(problem_identifier, include_file_name) + root_cause)

        # Now begin getting static version from server

        # WW server can react to a
        #   URL of a problem stored there already
        #   or a base64 encoding of a problem
        # server_params is tuple rather than dictionary to enforce consistent order in url parameters
        server_params = (('answersSubmitted','0'),
                         ('displayMode','PTX'),
                         ('courseID',courseID),
                         ('userID',userID),
                         ('password',password),
                         ('course_password',course_password),
                         ('outputformat','ptx'),
                         ('sourceFilePath',source[problem]) if origin[problem] == 'server' else ('problemSource',pgbase64['hint_yes_solution_yes'][problem]),
                         ('problemSeed',seed[problem]))

        msg = "sending {} to server to save in {}: origin is '{}'"
        _verbose(msg.format(problem, dest_dir, origin[problem]))
        if origin[problem] == 'server':
            _debug('server-to-ptx: {} {} {} {}'.format(source[problem], wwurl, dest_dir, problem))
        elif origin[problem] == 'ptx':
            _debug('server-to-ptx: {} {} {} {}'.format(pgptx['hint_yes_solution_yes'][problem], wwurl, dest_dir, problem))

        # Ready, go out on the wire
        try:
            response = session.get(wwurl, params=server_params)
        except requests.exceptions.RequestException as e:
            root_cause = str(e)
            msg = "There was a problem collecting a problem,\n Server: {}\nRequest Parameters: {}\n"
            raise ValueError(msg.format(wwurl, server_params) + root_cause)

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

        # Check for errors with PG processing
        # Get booleans signaling badness: file_empty, no_compile, bad_xml, no_statement
        file_empty = 'ERROR:  This problem file was empty!' in response_text
        no_compile = 'ERROR caught by Translator while processing problem file:' in response_text
        bad_xml = False
        no_statement = False
        try:
            from xml.etree import ElementTree
        except ImportError:
            msg = 'failed to import ElementTree from xml.etree'
            raise ValueError(msg)
        try:
            problem_root = ElementTree.fromstring(response_text)
        except:
            bad_xml = True
        if not bad_xml:
            if problem_root.find('.//statement') is None:
                no_statement = True
        badness = file_empty or no_compile or bad_xml or no_statement

        # Custom responses for each type of badness
        # message for terminal log
        # tip reminding about -a (abort) option
        # value for @failure attribute in static element
        # base64 for a shell PG problem that simply indicates there was an issue and says what the issue was
        if file_empty:
            badness_msg = "PTX:ERROR:  WeBWorK problem {} was empty\n"
            badness_tip = ''
            badness_type = 'empty'
            badness_base64 = 'RE9DVU1FTlQoKTsKbG9hZE1hY3JvcygiUEdzdGFuZGFyZC5wbCIsIlBHTUwucGwiLCJQR2NvdXJzZS5wbCIsKTtURVhUKGJlZ2lucHJvYmxlbSgpKTtDb250ZXh0KCdOdW1lcmljJyk7CgpCRUdJTl9QR01MCldlQldvcksgUHJvYmxlbSBGaWxlIFdhcyBFbXB0eQoKRU5EX1BHTUwKCkVORERPQ1VNRU5UKCk7'
        elif no_compile:
            badness_msg = "PTX:ERROR:  WeBWorK problem {} with seed {} did not compile  \n{}\n"
            badness_tip = '  Use -a to halt with full PG and returned content' if (origin[problem] == 'ptx') else '  Use -a to halt with returned content'
            badness_type = 'compile'
            badness_base64 = 'RE9DVU1FTlQoKTsKbG9hZE1hY3JvcygiUEdzdGFuZGFyZC5wbCIsIlBHTUwucGwiLCJQR2NvdXJzZS5wbCIsKTtURVhUKGJlZ2lucHJvYmxlbSgpKTtDb250ZXh0KCdOdW1lcmljJyk7CgpCRUdJTl9QR01MCldlQldvcksgUHJvYmxlbSBEaWQgTm90IENvbXBpbGUKCkVORF9QR01MCgpFTkRET0NVTUVOVCgpOw%3D%3D'
        elif bad_xml:
            badness_msg = "PTX:ERROR:  WeBWorK problem {} with seed {} does not return valid XML  \n  It may not be PTX compatible  \n{}\n"
            badness_tip = '  Use -a to halt with returned content'
            badness_type = 'xml'
            badness_base64 = 'RE9DVU1FTlQoKTsKbG9hZE1hY3JvcygiUEdzdGFuZGFyZC5wbCIsIlBHTUwucGwiLCJQR2NvdXJzZS5wbCIsKTtURVhUKGJlZ2lucHJvYmxlbSgpKTtDb250ZXh0KCdOdW1lcmljJyk7CgpCRUdJTl9QR01MCldlQldvcksgUHJvYmxlbSBEaWQgTm90IEdlbmVyYXRlIFZhbGlkIFhNTAoKRU5EX1BHTUwKCkVORERPQ1VNRU5UKCk7'
        elif no_statement:
            badness_msg = "PTX:ERROR:  WeBWorK problem {} with seed {} does not have a statement tag \n  Maybe it uses something other than BEGIN_TEXT or BEGIN_PGML to print the statement in its PG code \n{}\n"
            badness_tip = '  Use -a to halt with returned content'
            badness_type = 'statement'
            badness_base64 = 'RE9DVU1FTlQoKTsKbG9hZE1hY3JvcygiUEdzdGFuZGFyZC5wbCIsIlBHTUwucGwiLCJQR2NvdXJzZS5wbCIsKTtURVhUKGJlZ2lucHJvYmxlbSgpKTtDb250ZXh0KCdOdW1lcmljJyk7CgpCRUdJTl9QR01MCldlQldvcksgUHJvYmxlbSBEaWQgTm90IEhhdmUgYSBbfHN0YXRlbWVudHxdKiBUYWcKCkVORF9QR01MCgpFTkRET0NVTUVOVCgpOw%3D%3D'

        # If we are aborting upon recoverable errors...
        if args.abort:
            if badness:
                debugging_help = response_text
                if origin[problem] == 'ptx' and no_compile:
                    debugging_help += "\n" + pg[problem]
                raise ValueError(badness_msg.format(problem_identifier, seed[problem], debugging_help))

        # If there is "badness"...
        # Build 'shell' problems to indicate failures
        if badness:
            print(badness_msg.format(problem_identifier, seed[problem], badness_tip))
            static_skeleton = "<static failure='{}'>\n<statement>\n  <p>\n    {}  </p>\n</statement>\n</static>\n"
            static[problem] = static_skeleton.format(badness_type, badness_msg.format(problem_identifier, seed[problem], badness_tip))

        else:
            # add to dictionary
            static[problem] = response_text
            # strip out actual PTX code between markers
            start = start_marker.split(static[problem], maxsplit=1)
            static[problem] = start[1]
            end = end_marker.split(static[problem], maxsplit=1)
            static[problem] = end[0]
            # change element from webwork to static and indent
            static[problem] = static[problem].replace('<webwork>', '<static>')
            static[problem] = static[problem].replace('</webwork>', '</static>')

        # Convert answerhashes XML to a sequence of answer elements
        # This is crude text operation on the XML
        # If correct_ans_latex_string is nonempty, use it, encased in <p><m>
        # Else if correct_ans is nonempty, use it, encased in just <p>
        # Else we have no answer to print out
        answerhashes = re.findall(r'<AnSwEr\d+ (.*?) />', static[problem], re.DOTALL)
        if answerhashes:
            answer = ''
            for answerhash in answerhashes:
                try:
                    correct_ans = re.search('correct_ans="(.*?)"', answerhash, re.DOTALL).group(1)
                except:
                    correct_ans = ''
                try:
                    correct_ans_latex_string = re.search('correct_ans_latex_string="(.*?)"', answerhash, re.DOTALL).group(1)
                except:
                    correct_ans_latex_string = ''

                if correct_ans_latex_string or correct_ans:
                    answer += "<answer>\n  <p>"
                    if not correct_ans_latex_string:
                        answer += correct_ans
                    else:
                        answer += '<m>' + correct_ans_latex_string + '</m>'
                    answer += "</p>\n</answer>\n"

            # Now we need to cut out the answerhashes that came from the server.
            beforehashes = re.compile('<answerhashes>').split(static[problem])[0]
            afterhashes = re.compile('</answerhashes>').split(static[problem])[1]
            static[problem] = beforehashes + afterhashes

            # We don't just replace it with the answer we just built. To be
            # schema-compliant, the answer should come right after the latter of
            # (last closing statement, last closing hint)
            # By reversing the string, we can just target first match
            reverse = static[problem][::-1]
            parts = re.split(r"(\n>tnemetats/<|\n>tnih/<)",reverse, 1)
            static[problem] = parts[2][::-1] + parts[1][::-1] + answer + parts[0][::-1]

        # nice to know what seed was used
        static[problem] = static[problem].replace('<static', '<static seed="' + seed[problem] + '"')

        # nice to know sourceFilePath for server problems
        if origin[problem] == 'server':
            static[problem] = static[problem].replace('<static', '<static source="' + source[problem] + '"')

        # adjust indentation
        static[problem] = re.sub(re.compile('^(?=.)', re.MULTILINE),'      ',static[problem]).replace('  <static','<static').replace('  </static','</static')
        # remove excess blank lines that come at the end from the server
        static[problem] = re.sub(re.compile('\n+( *</static>)', re.MULTILINE),r"\n\1",static[problem])

        # need to loop through content looking for images with pattern:
        #
        #   <image source="relative-path-to-temporary-image-on-server"
        #
        graphics_pattern = re.compile(r'<image.*?source="([^"]*)"')

        # replace filenames, download images with new filenames
        count = 0
        # ww_image_url will be the URL to an image file used by the problem on the ww server
        for match in re.finditer(graphics_pattern, static[problem]):
            ww_image_url = match.group(1)
            # strip away the scheme and location, if present (e.g 'https://webwork-ptx.aimath.org/')
            ww_image_url_parsed = urlparse(ww_image_url)
            ww_image_scheme = ww_image_url_parsed.scheme
            ww_image_full_path = ww_image_url_parsed.path
            count += 1
            # split the full path into (path, file). path could theoretically be empty.
            ww_image_path, ww_image_filename = os.path.split(ww_image_full_path)
            # split the filename into (name, extension). extension can be empty or like '.png'.
            ww_image_name, image_extension = os.path.splitext(ww_image_filename)
            # rename, eg, webwork-extraction/webwork-5-image-3.png
            ptx_image_name =  problem + '-image-' + str(count)
            ptx_image_filename = ptx_image_name + image_extension
            if ww_image_scheme:
                image_url = ww_image_url
            else:
                image_url = server_url + ww_image_full_path
            # modify PTX problem source to include local versions
            static[problem] = static[problem].replace(ww_image_full_path, 'images/' + ptx_image_filename)
            # download actual image files
            # http://stackoverflow.com/questions/13137817/how-to-download-image-using-requests
            try:
                response = session.get(image_url)
            except requests.exceptions.RequestException as e:
                root_cause = str(e)
                msg = "There was a problem downloading an image file,\n URL: {}\n"
                raise ValueError(msg.format(image_url) + root_cause)
            # and save the image itself
            try:
                with open(os.path.join(dest_dir, ptx_image_filename), 'wb') as image_file:
                    image_file.write(response.content)
            except Exception as e:
                root_cause = str(e)
                msg = "There was a problem saving an image file,\n Filename: {}\n"
                raise ValueError(os.path.join(dest_dir, ptx_filename) + root_cause)

        # place static content
        # we open the file in binary mode to preserve the \r characters that may be present
        try:
            with open(include_file_name, 'ab') as include_file:
                if PY3:
                    include_file.write(bytes(static[problem] + '\n', encoding='utf-8'))
                else:
                    include_file.write(static[problem] + '\n')
        except Exception as e:
            root_cause = str(e)
            msg = "There was a problem writing a problem to the file: {}\n"
            raise ValueError(msg.format(include_file_name) + root_cause)

        # Write urls for interactive version
        for hint in ['yes','no']:
            for solution in ['yes','no']:
                hintsol = 'hint_' + hint + '_solution_' + solution
                url_tag = '    <server-url hint="{}" solution="{}">{}?courseID={}&amp;userID={}&amp;password={}&amp;course_password={}&amp;answersSubmitted=0&amp;displayMode=MathJax&amp;outputformat=simple&amp;problemSeed={}&amp;{}</server-url>\n\n'
                source_selector = 'problemSource=' if (badness or origin[problem] == 'ptx') else 'sourceFilePath='
                if badness:
                    source_value = badness_base64
                else:
                    if origin[problem] == 'server':
                        source_value = source[problem]
                    elif PY3:
                        source_value = urllib.parse.quote_plus(pgbase64[hintsol][problem])
                    else:
                        source_value = urllib.quote_plus(pgbase64[hintsol][problem])
                source_query = source_selector + source_value
                try:
                    with open(include_file_name, 'a') as include_file:
                        include_file.write(url_tag.format(hint,solution,wwurl,courseID,userID,password,course_password,seed[problem],source_query))
                except Exception as e:
                    root_cause = str(e)
                    msg = "There was a problem writing URLs for {} to the file: {}\n"
                    raise ValueError(msg.format(problem_identifier, include_file_name) + root_cause)

        # Write PG. For server problems, just include source as attribute and close pg tag
        if origin[problem] == 'ptx':
            pg_tag = '    <pg>\n{}\n    </pg>\n\n'
            if badness:
                formatted_pg = pg_shell.format(badness_msg.format(problem_identifier, seed[problem], badness_tip))
            else:
                formatted_pg = pg[problem]
            # opportunity to cut out extra blank lines
            formatted_pg = re.sub(re.compile(r"(\n *\n)( *\n)*", re.MULTILINE),r"\n\n",formatted_pg)

            try:
                with open(include_file_name, 'a') as include_file:
                    include_file.write(pg_tag.format(formatted_pg))
            except Exception as e:
                root_cause = str(e)
                msg = "There was a problem writing the PG for {} to the file: {}\n"
                raise ValueError(msg.format(problem_identifier, include_file_name) + root_cause)
        elif origin[problem] == 'server':
            try:
                with open(include_file_name, 'a') as include_file:
                    pg_tag = '    <pg source="{}" />\n\n'
                    include_file.write(pg_tag.format(source[problem]))
            except Exception as e:
                root_cause = str(e)
                msg = "There was a problem writing the PG for {} to the file: {}\n"
                raise ValueError(msg.format(problem_identifier, include_file_name) + root_cause)

        # close webwork-reps tag
        try:
            with open(include_file_name, 'a') as include_file:
                include_file.write('  </webwork-reps>\n\n')
        except Exception as e:
            root_cause = str(e)
            msg = "There was a problem writing a problem to the file: {}\n"
            raise ValueError(msg.format(include_file_name) + root_cause)

    # close webwork-extraction tag and finish
    try:
        with open(include_file_name, 'a') as include_file:
            include_file.write('</webwork-extraction>')
    except Exception as e:
        root_cause = str(e)
        msg = "There was a problem writing a problem to the file: {}\n"
        raise ValueError(msg.format(include_file_name) + root_cause)


##############################
#
#  You Tube thumbnail scraping
#
##############################

def youtube_thumbnail(xml_source, xmlid_root, dest_dir):
    global config
    import tempfile, os, os.path, subprocess, shutil
    import requests

    _verbose('downloading YouTube thumbnails from {} for placement in {}'.format(xml_source, dest_dir))
    dest_dir = sanitize_directory(dest_dir)
    plat = get_platform()
    if plat == "Windows":
        dest_dir = break_windows_path(dest_dir)
    xslt_executable = get_executable(config,  'xslt')
    _debug("xslt executable: {}".format(xslt_executable))
    if plat == "Windows":
        extraction_xslt = '/'.join([mbx_xsl_dir, 'extract-youtube.xsl'])
    else:
        extraction_xslt = os.path.join(mbx_xsl_dir, 'extract-youtube.xsl')
    cmd = [xslt_executable,
            '--xinclude',
            '--stringparam',
            'subtree',
            xmlid_root,
            extraction_xslt,
            xml_source]
    try:
        thumb_list = subprocess.check_output(cmd)
    except subprocess.CalledProcessError as e:
        root_cause = str(e)
        msg = 'xsltproc command failed, tried: "{}"\n'.format(' '.join(cmd))
        raise ValueError(msg + root_cause)
    # "run" an assignment for the list of triples of strings
    thumbs = eval(thumb_list.decode('ascii'))

    yt_url = 'http://i.ytimg.com/vi/{}/default.jpg'
    image_path = dest_dir + '/{}.jpg'
    session = requests.Session()
    for thumb in thumbs:
        url = yt_url.format(thumb[0])
        path = image_path.format(thumb[1])
        _verbose('downloading {} as {}...'.format(url, path))
        # http://stackoverflow.com/questions/13137817/how-to-download-image-using-requests/13137873
        # removed some settings wrapper from around the URL, otherwise verbatim
        r = requests.get(url, stream=True)
        if r.status_code == 200:
            with open(path, 'wb') as f:
                r.raw.decode_content = True
                shutil.copyfileobj(r.raw, f)
        else:
            msg = 'Download returned a bad status code ({}), perhaps try {} manually?'
            raise OSError(msg.format(r.status_code, url))
    _verbose('YouTube thumbnail download complete')


#####################################
#
#  Interactive preview screenshotting
#
#####################################

def preview_images(xml_source, xmlid_root, dest_dir):
    global config
    import subprocess, shutil
    import os
    # import tempfile, os, os.path, subprocess, shutil
    # import requests

    suffix = 'png'

    _verbose('creating interactive previews from {} for placement in {}'.format(xml_source, dest_dir))
    dest_dir = sanitize_directory(dest_dir)

    # see below, pageres-cli writes into current working directory
    needs_moving = not( os.getcwd() == os.path.normpath(dest_dir) )

    # url standalone page, id on iframe, filename to store
    previews = (
        ("http://mathbook.pugetsound.edu/examples/sample-article/html/interactive-d3-graph-layout.html",
                    "interactive-d3-graph-layout", "interactive-d3-graph-layout-preview.png"),
        ("http://mathbook.pugetsound.edu/examples/sample-article/html/interactive-d3-collision.html",
                    "interactive-d3-collision", "interactive-d3-collision-preview.png"),
        )

    plat = get_platform()
    if plat == "Windows":
        dest_dir = break_windows_path(dest_dir)
    xslt_executable = get_executable(config,  'xslt')
    _debug("xslt executable: {}".format(xslt_executable))
    if plat == "Windows":
        extraction_xslt = '/'.join([mbx_xsl_dir, 'extract-interactive.xsl'])
    else:
        extraction_xslt = os.path.join(mbx_xsl_dir, 'extract-interactive.xsl')
    cmd = [xslt_executable,
            '--xinclude',
            '--stringparam',
            'subtree',
            xmlid_root,
            extraction_xslt,
            xml_source]
    try:
        interactive_list = subprocess.check_output(cmd)
    except subprocess.CalledProcessError as e:
        root_cause = str(e)
        msg = 'xsltproc command failed, tried: "{}"\n'.format(' '.join(cmd))
        raise ValueError(msg + root_cause)
    # "run" an assignment for the list of problem numbers
    interactives = eval(interactive_list.decode('ascii'))

    # Cheating a bit, base URL is *always* first item
    # Presumed to not have a trailing slash
    # Once this is a publisher option, then the xsltproc
    # call will need to accept the override as a stringparam
    baseurl = interactives[0]

    pageres_executable = get_executable(config,  'pageres')
    _debug("pageres executable: {}".format(xslt_executable))
    _debug("interactives identifiers: {}".format(interactives))

    # Start after the leading base URL sneakiness
    for preview in interactives[1:]:
        input_page = baseurl + '/' +  preview + '.html'
        selector_option = '--selector=#' + preview
        # file suffix is provided by pageres
        format_option = '--format=' + suffix
        filename_option = '--filename=' + preview + '-preview'
        filename = preview + '-preview.' + suffix

        # pageres invocation
        # Overwriting files prevents numbered versions (with spaces!)
        # 3-second delay allows Javascript, etc to settle down
        # --transparent, --crop do not seem very effective
        # if (preview == "interactive-21") or (preview == "interactive-17")  or (preview == "interactive-19") or (preview == "interactive-20"):
            # cmd=['ls']
        # else:
        cmd = [pageres_executable,
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
        # 2018-04-27  CLI pageres only writes into current directory
        # and it is an error to move a file onto itself, so we are careful
        if needs_moving:
            shutil.move(filename, dest_dir)


#####################################
#
#  MyOpenMath static problem scraping
#
#####################################

def mom_static_problems(xml_source, xmlid_root, dest_dir):
    global config
    import tempfile, os, os.path, subprocess, shutil
    import requests

    _verbose('downloading MyOpenMath static problems from {} for placement in {}'.format(xml_source, dest_dir))
    dest_dir = sanitize_directory(dest_dir)
    plat = get_platform()
    if plat == "Windows":
        dest_dir = break_windows_path(dest_dir)
    xslt_executable = get_executable(config,  'xslt')
    _debug("xslt executable: {}".format(xslt_executable))
    if plat == "Windows":
        extraction_xslt = '/'.join([mbx_xsl_dir, 'extract-mom.xsl'])
    else:
        extraction_xslt = os.path.join(mbx_xsl_dir, 'extract-mom.xsl')
    cmd = [xslt_executable,
            '--xinclude',
            '--stringparam',
            'subtree',
            xmlid_root,
            extraction_xslt,
            xml_source]
    try:
        problem_list = subprocess.check_output(cmd)
    except subprocess.CalledProcessError as e:
        root_cause = str(e)
        msg = 'xsltproc command failed, tried: "{}"\n'.format(' '.join(cmd))
        raise ValueError(msg + root_cause)
    # "run" an assignment for the list of problem numbers
    problems = eval(problem_list.decode('ascii'))
    mom_url = 'https://www.myopenmath.com/util/mbx.php?id={}'
    xml_header = '<?xml version="1.0" encoding="UTF-8" ?>\n'
    path_string = dest_dir + '/mom-{}.xml'
    session = requests.Session()
    for problem in problems:
        url = mom_url.format(problem)
        path = path_string.format(problem)
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
                msg = 'Download returned a bad status code ({}), perhaps try {} manually?'
                raise OSError(msg.format(r.status_code, url))
    _verbose('MyOpenMath static problem download complete')


#######################################
#
# Sage Worksheet Creation and Packaging
#
#######################################

# Conversion object adapted/simplified from  tex2sws  project (c. 2010)

# TODO: patrol normalized paths for Windows compatibility (universally)
# TODO: Cleanup temporay directory if not -vv

class MathBookXMLtoSWS(object):

    def __init__(self, xslt_exec, mbx_dir, xml_file, sws_file):
        r"""
        Configure the working environment for a conversion.

        INPUT:

        - ``xslt_exec`` - XSLT executable

        - ``mbx_dir`` - root of MBX distribution

        - ``xml_file`` - a MathBook XML file to convert
          to a Sage Notebook file

        - ``sws_file`` - final name/location of Sage Notebook file

        OUTPUT:
        An sws format file for the Sage Notebook reflecting the document.
        """
        import os.path   # join
        import tempfile  # mkdtemp

        _verbose('converting {} to {}'.format(xml_file, sws_file))

        if not xml_file:
            raise ValueError('an XML file for input must be specified')
        if not sws_file:
            raise ValueError('an SWS file for output must be specified')

        _debug('MBX, XML, SWS locations: {}, {}, {}'.format(mbx_dir, xml_file, sws_file))

        # Record locations for use later in the class
        # Prior to making/using temporary directory
        self._xml_file = os.path.abspath(xml_file)
        self._sws_file = os.path.abspath(sws_file)
        self._xsltproc_exec = xslt_exec
        self._mathbook_xslt = os.path.join(mbx_dir, 'xsl/mathbook-sagenb.xsl')
        # Whole book as Sage worksheets
        # self._mathbook_xslt = '/home/rob/books/aata/aata/xsl/aata-sagenb.xsl'
        # Just exercises as Sage worksheets
        # self._mathbook_xslt = '/home/rob/books/aata/aata/xsl/aata-sage-exercises.xsl'
        self._source_dir = get_source_path(self._xml_file)
        self._tmp_dir = tempfile.mkdtemp()
        _debug('xslt exec, MB XSL, source-dir, temp-dir: {}, {}, {}, {}'.format(self._xsltproc_exec, self._mathbook_xslt, self._source_dir, self._tmp_dir))

    def _process_xml(self):
        import os
        import subprocess

        _verbose('extracting files and assets from XML file via XSLT')
        os.chdir(self._tmp_dir)
        devnull = open(os.devnull, 'w')
        content_cmd = [self._xsltproc_exec, '--xinclude',
                       '--stringparam', 'purpose', 'files',
                       self._mathbook_xslt, self._xml_file
                      ]
        subprocess.call(content_cmd)
        info_cmd = [self._xsltproc_exec, '--xinclude',
                       '--stringparam', 'purpose', 'info',
                       self._mathbook_xslt, self._xml_file
                      ]
        # info will be a list, each element a pair
        # first a filename, then a list of included files
        info = subprocess.check_output(info_cmd)
        manifest = eval(info.decode('ascii'))
        _debug('Manifest, information list: {}'.format(manifest))
        return manifest


    def _create_single_sws(self, html_file, title, assets):
        r"""
        Create a single Sage worksheet in SWS format.

        INPUTS:

        - ``html_file`` - name of an HTML file of "raw" content

        - ``title`` - string for title

        - ``assets`` - a list of (image) files to place
          in the worksheet data directory

        This routine creates a worksheet "from scratch" using just Python
        and none of the notebook code.  This makes for quicker startup times
        and the ability to run without Sage present.

        OUTPUT:  This routine places a Sage worksheet in the main
        temporary directory.  Later we determine if there are more.
        """
        import time  # for last change in pickled worksheet info
        import tempfile
        import tarfile
        import pickle
        import os
        import os.path  # join, split, splitext
        import glob     # find PNG's of SVg's

        # Make a generic worksheet configuration as a Python dictionary
        basic = {
            'name': title,
            'system': 'sage',
            'owner': 'admin',
            'last_change': ('admin', time.time()),
            }

        basename, _ = os.path.splitext(html_file)
        base_dir = 'sage_worksheet'
        data_dir = 'data'

        # Build sws as a tar file
        sws_file = '{}.sws'.format(basename)
        T = tarfile.open(sws_file, 'w:bz2')

        # Pickle configuration file
        # Write into temp file, add to sws file
        fd, configfile =  tempfile.mkstemp()
        config = pickle.dumps(basic)
        open(configfile, 'w').write(config)
        T.add(configfile, os.path.join(base_dir, 'worksheet_conf.pickle'))
        os.unlink(configfile)
        os.fdopen(fd,'w').close()

        # Worksheet file, new style (.html suffix)
        _debug('Making "worksheet.html" in sws archive from {}'.format(html_file))
        T.add(html_file, arcname=os.path.join(base_dir, 'worksheet.html'))

        # Worksheet file, old style (prepend two-line header, .txt suffix)
        _debug('Making "worksheet.txt" in sws archive from {}'.format(html_file))
        header = '{}\nsystem: sage\n'.format(title)
        original = open(html_file, 'r').read()
        fd, oldstyle =  tempfile.mkstemp()
        open(oldstyle, 'w').write(header + original)
        T.add(oldstyle, arcname=os.path.join(base_dir, 'worksheet.txt'))
        os.unlink(oldstyle)
        os.fdopen(fd,'w').close()

        # add various necessary files from asset list
        for afile in assets:
            source = os.path.join(self._source_dir, afile)
            # XSLT produces SVG file names for generated plots
            # PNG is the fallback, esp for <sageplot>
            if not(os.path.isfile(source)):
                source = source[:-3] + 'png'
                afile = afile[:-3] + 'png'
            dest = os.path.join(base_dir, data_dir, afile)
            _debug('adding {} to sws archive as {}'.format(source, dest))
            T.add(source, arcname=dest)
            # look for Asymptote SVG's which include similarly-named PNG's
            base, ext = os.path.splitext(afile)
            if ext in ['.svg', '.SVG']:
                pattern = os.path.join(self._source_dir, base + '_*.png')
                for f in glob.glob(pattern):
                    _, includedfile = os.path.split(f)
                    dest = os.path.join(base_dir, data_dir, base + '_*.png')
                    T.add(f, arcname=dest)

        T.close()
        return sws_file

    def _package_worksheets(self, worksheets):
        r"""
        Rename/move single worksheet, or zip a collection.

        INPUTS:

        - ``worksheets`` - a list of worsheet file names, no paths

        OUTPUT:  One SWS file, or several collected in a zip archive.
        """
        import os.path # splitext
        import shutil  # copy2
        import zipfile # Zipfile

        destination = self._sws_file  # perhaps really a zip file
        _verbose('Manufacturing final notebook-compatible file: {}'.format(destination))
        _debug('Packaging following SWS files: {}'.format(worksheets))

        # Sanity checks on worksheets, filename
        if len(worksheets) == 0:
            raise ValueError('XSLT transform produced no output, check configuration')
        single = (len(worksheets) == 1)
        _, ext = os.path.splitext(destination)
        if single:
            if not(ext in ['.sws', '.SWS']):
                msg = 'creating a single worksheet, filename should end in ".sws", not "{}"'
                raise ValueError(msg.format(ext))
        else:
            if not(ext in ['.zip', '.ZIP']):
                msg = 'creating multiple worksheets, filename should end in ".zip", not "{}"'
                raise ValueError(msg.format(ext))
        if single:
            # Singe worksheet: copy from temp/working to final resting place
            # Prepend temp directory
            sws = os.path.join(self._tmp_dir, worksheets[0])
            shutil.copy2(sws, destination)
        else:
            # Multiple worksheets: manufactured in final resting place
            Z = zipfile.ZipFile(destination, 'w')
            for afile in worksheets:
                Z.write(afile)
            Z.close()


    def convert(self):
        r"""
        The one public method.
        """
        import subprocess
        import os.path

        worksheets = []
        info = self._process_xml()
        # Creating early portions of the document later in time
        # provides later timestamps and places them lower in the
        # time-sorted worksheet-list of the Sage notebook interface
        for afile in reversed(info):
            _verbose('Converting {} to an SWS file'.format(afile[0]))
            sws_file = self._create_single_sws(afile[0], afile[1], afile[2])
            worksheets.append(sws_file)
        self._package_worksheets(worksheets)


###################
#
# Utility Functions
#
###################

def _verbose(msg):
    """Write a message to the console on program progress"""
    global args
    # None if not set at all
    if args.verbose and args.verbose >= 1:
        print('MBX: {}'.format(msg))


def _debug(msg):
    """Write a message to the console with some raw information"""
    global args
    # None if not set at all
    if args.verbose and args.verbose >= 2:
        print('MBX-DEBUG: {}'.format(msg))


def get_mbx_path():
    """Returns path of root of MBX distribution"""
    import sys, os.path
    _verbose("discovering MBX root directory from mbx script location")
    # full path to script itself
    mbx_path = os.path.abspath(sys.argv[0])
    # split "mbx" executable off path
    script_dir, _ = os.path.split(mbx_path)
    # split "script" path off executable
    distribution_dir, _ = os.path.split(script_dir)
    _verbose("MBX distribution root directory: {}".format(distribution_dir))
    return distribution_dir


def get_source_path(source_file):
    """Returns path of source XML file"""
    import sys, os.path
    _verbose("discovering source directory from source location")
    # split path off filename
    source_dir, _ = os.path.split(source_file)
    return os.path.normpath(source_dir)

def get_executable(config, exec_name):
    "Queries configuration file for executable name, verifies existence in Unix"
    import os
    import platform
    import subprocess

    # http://stackoverflow.com/questions/11210104/check-if-a-program-exists-from-a-python-script
    # suggests  where.exe  as Windows equivalent (post Windows Server 2003)
    # which  = 'where.exe' if platform.system() == 'Windows' else 'which'

    # get the name, but then see if it really, really works
    _debug('locating "{}" in [executables] section of configuration file'.format(exec_name))
    config_name = config.get('executables', exec_name)

    devnull = open(os.devnull, 'w')
    try:
        result_code = subprocess.call(['which', config_name], stdout=devnull, stderr=subprocess.STDOUT)
    except OSError:
        print('MBX:WARNING: executable existence-checking was not performed (e.g. on Windows)')
        result_code = 0  # perhaps a lie on Windows
    if result_code != 0:
        error_message = '\n'.join([
                        'cannot locate executable with configuration name "{}" as command "{}"',
                        'Edit the configuration file and/or install the necessary program'])
        raise OSError(error_message.format(exec_name, config_name))
    _debug("{} executable: {}".format(exec_name, config_name))
    return config_name

def get_cli_arguments():
    """Return the CLI arguments in parser object"""
    import argparse
    parser = argparse.ArgumentParser(description='MathBook XML utility script', formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument("--version", action="version", version="%(prog)s " + __version__)

    verbose_help = '\n'.join(["verbosity of information on progress of the program",
                              "  -v  is actions being performed",
                              "  -vv is some additional raw debugging information"])
    parser.add_argument('-v', '--verbose', help=verbose_help, action="count")

    component_info = [
        ('asy', 'Asymptote diagrams'),
        ('sageplot', 'Sage graphics'),
        ('latex-image', 'LaTeX pictures'),
        ('webwork', 'WeBWorK problems in authored, PG, url, and static representations'),
        ('youtube', 'Thumbnails for YouTube videos (JPEG only)'),
        ('preview', 'Static preview images for interactives'),
        ('mom', 'MyOpenMath problem files, static versions'),
        ('all', 'Complete document (only SageNB format)'),
        ('tikz', 'tikz pictures (obsolete)'),
    ]
    component_help = 'Possible components are:\n' + '\n'.join(['  {} - {}'.format(info[0], info[1]) for info in component_info])
    parser.add_argument('-c', '--component', help=component_help, action="store", dest="component")

    format_info = [
        ('svg', 'Scalable Vector Graphicsfile(s)'),
        ('pdf', 'Portable Document Format file(s)'),
        ('png', 'Portable Network Graphics file(s)'),
        ('eps', 'Encapsulated Post Script file(s)'),
        ('source', 'Standalone source files'),
        ('latex', 'LaTeX source file'),
        ('html', 'HyperText Markup Language (web pages)'),
        ('sagenb', 'Sage *.sws archive of worksheets'),
        ('all', 'All available output formats'),
    ]
    format_help = 'Output formats are:\n' + '\n'.join(['  {} - {}'.format(info[0], info[1]) for info in format_info])
    parser.add_argument('-f', '--format', help=format_help, action="store", dest='format')

    # "nargs" allows multiple options following the flag
    # separate by spaces, can't use "-stringparam"
    # stringparams is a list of strings on return
    parser.add_argument('-p', '--parameters', nargs='+', help='stringparam options to pass to XSLT extraction stylesheet (option/value pairs)',
                         action="store", dest='stringparams')

    # default to an empty string, which signals root to XSL stylesheet
    parser.add_argument('-r', '--restrict', help='restrict to subtree rooted at element with specified xml:id',
                         action="store", dest='xmlid', default='')

    parser.add_argument('-s', '--server', help='base URL for server (webwork only)', action="store", dest='server')

    parser.add_argument('-i', '--include', help='external data directory, relative to source, latex-image only', action="store", dest='data_dir')
    parser.add_argument('-o', '--output', help='file for output', action="store", dest='out')
    parser.add_argument('-d', '--directory', help='directory for output', action="store", dest='dir')
    parser.add_argument('-a', '--abort', help='abort script upon recoverable errors', action="store_true", dest='abort')

    parser.add_argument('xml_file', help='MathBook XML source file with content', action="store")

    return parser.parse_args()


def sanitize_directory(dir):
    """Verify directory name, or raise error"""
    # Use with os.path.join, and do not sweat separator
    import os.path
    _verbose('verifying directory: {}'.format(dir))
    if not(os.path.isdir(dir)):
        raise ValueError('directory {} does not exist'.format(dir))
    return dir

def sanitize_url(url):
    """Verify a server address, append a slash"""
    _verbose('validating, cleaning server URL: {}'.format(url))
    import requests
    try:
        requests.get(url)
    except requests.exceptions.RequestException as e:
        root_cause = str(e)
        msg = "There was a problem with the server URL, {}\n".format(url)
        raise ValueError(msg + root_cause)
    # We expect relative paths to locations on the server
    # So we add a slash if there is not one already
    if url[-1] != "/":
        url = url + "/"
    return url

def sanitize_alpha_num_underscore(param):
    """Verify parameter is a string containing only alphanumeric and undescores"""
    import string
    allowed = set(string.ascii_letters + string.digits + '_')
    _verbose('verifying parameter: {}'.format(param))
    if not(set(param) <= allowed):
        raise ValueError('param {} contains characters other than a-zA-Z0-9_ '.format(param))
    return param

def get_config_info(script_dir, user_dir):
    """Return configuation in object for querying"""
    import sys,os.path
    config_filename = "mbx.cfg"
    default_config_file = os.path.join(script_dir, config_filename)
    user_config_file = os.path.join(user_dir, config_filename)
    config_file_list = [default_config_file, user_config_file]
    # ConfigParser was renamed to configparser in Python 3
    try:
        import configparser
    except ImportError:
        import ConfigParser as configparser
    config = configparser.SafeConfigParser()
    _verbose("parsing configuration files: {}".format(config_file_list))
    files_read = config.read(config_file_list)
    _debug("configuration files used/read: {}".format(files_read))
    if not(user_config_file in files_read):
        msg = "using default configuration only, custom configuration file not used at {}"
        _verbose(msg.format(user_config_file))
    return config

def copy_data_directory(source_file, data_dir, tmp_dir):
    """Stage directory from CLI argument into the working directory"""
    import os.path, shutil
    _verbose("formulating data directory location")
    source_full_path, _ = os.path.split(os.path.abspath(source_file))
    data_full_path = sanitize_directory(os.path.join(source_full_path, data_dir))
    data_last_step = os.path.basename(os.path.normpath(data_full_path))
    destination_root = os.path.join(tmp_dir, data_last_step)
    _debug("copying data directory {} to working location {}".format(data_full_path, destination_root))
    shutil.copytree(data_full_path, destination_root)

def get_platform():
    """Return a string that tells us whether we are on Windows."""
    import platform
    return platform.system()

def is_os_64bit():
    """Return true if we are running a 64-bit OS.
    http://stackoverflow.com/questions/2208828/detect-64-bit-os-windows-in-python"""
    import platform
    return platform.machine().endswith('64')

def break_windows_path(python_style_dir):
    """Replace python os.sep with msys-acceptable "/" """
    import re
    return re.sub(r"\\", "/", python_style_dir)

######
#
# Main
#
######

import os.path, sys

def main():
    # Parse command line
    # Deduce some paths
    # Read configuration file
    # Switch on command line


    # grab command line arguments
    args = get_cli_arguments()
    _debug("CLI args {}".format(vars(args)))

    # Report Python version in debugging output
    msg = "Python version: {}.{} (expecting 2.7 or newer)"
    _debug(msg.format(sys.version_info[0], sys.version_info[1]))

    # directory locations relative to MathBook XML installation
    mbx_dir = get_mbx_path()
    mbx_xsl_dir = os.path.join(mbx_dir, "xsl")
    mbx_script_dir = os.path.join(mbx_dir, "script")
    mbx_user_dir = os.path.join(mbx_dir, "user")
    _debug("xsl, script, user dirs: {}".format([mbx_xsl_dir, mbx_script_dir, mbx_user_dir]))

    # directory location for outputs
    output_dir = os.path.abspath(args.dir)
    _debug("output dir: {}".format(output_dir))

    config = get_config_info(mbx_script_dir, mbx_user_dir)
    plat = get_platform()

    if args.component == 'tikz':
        if args.format == 'pdf':
            tikz_conversion(args.xml_file, args.xmlid, output_dir, 'pdf')
        elif args.format == 'svg':
            tikz_conversion(args.xml_file, args.xmlid, output_dir, 'svg')
        elif args.format == 'source':
            tikz_conversion(args.xml_file, args.xmlid, output_dir, 'source')
        else:
            raise NotImplementedError('cannot make TikZ pictures in "{}" format'.format(args.format))
    elif args.component == 'asy':
        if args.format == 'html':
            asymptote_conversion(args.xml_file, args.xmlid, output_dir, 'html')
        elif args.format == 'pdf':
            asymptote_conversion(args.xml_file, args.xmlid, output_dir, 'pdf')
        elif args.format == 'svg':
            asymptote_conversion(args.xml_file, args.xmlid, output_dir, 'svg')
        elif args.format == 'eps':
            asymptote_conversion(args.xml_file, args.xmlid, output_dir, 'eps')
        elif args.format == 'source':
            asymptote_conversion(args.xml_file, args.xmlid, output_dir, 'source')
        else:
            raise NotImplementedError('cannot make Asymptote diagrams in "{}" format'.format(args.format))
    elif args.component == 'sageplot':
        if args.format == 'pdf':
            sage_conversion(args.xml_file, args.xmlid, output_dir, 'pdf')
        elif args.format == 'svg':
            sage_conversion(args.xml_file, args.xmlid, output_dir, 'svg')
        elif args.format == 'source':
            sage_conversion(args.xml_file, args.xmlid, output_dir, 'source')
        else:
            raise NotImplementedError('cannot make Sage graphics in "{}" format'.format(args.format))
    elif args.component == 'latex-image':
        if args.format == 'pdf':
            latex_image_conversion(args.xml_file, args.stringparams, args.xmlid, args.data_dir, output_dir, 'pdf')
        elif args.format == 'svg':
            latex_image_conversion(args.xml_file, args.stringparams, args.xmlid, args.data_dir, output_dir, 'svg')
        elif args.format == 'source':
            latex_image_conversion(args.xml_file, args.stringparams, args.xmlid, args.data_dir, output_dir, 'source')
        elif args.format == 'png':
            latex_image_conversion(args.xml_file, args.stringparams, args.xmlid, args.data_dir, output_dir, 'png')
        elif args.format == 'eps':
            latex_image_conversion(args.xml_file, args.stringparams, args.xmlid, args.data_dir, output_dir, 'eps')
        elif args.format == 'all':
            latex_image_conversion(args.xml_file, args.stringparams, args.xmlid, args.data_dir, output_dir, 'all')
        else:
            raise NotImplementedError('cannot make LaTeX pictures in "{}" format'.format(args.format))
    elif args.component == 'webwork-tex':
        wtdep = ('the "webwork-tex" component has been replaced by the "webwork" component, '
                 'and behaves very differently')
        raise NotImplementedError(wtdep)
    elif args.component == 'webwork':
        xslt_executable = get_executable(config,  'xslt')
        _debug("xslt executable command: {}".format(xslt_executable))
        webwork_to_xml(xslt_executable, mbx_xsl_dir, args.xml_file, args.server, output_dir)
    elif args.component == 'youtube':
        youtube_thumbnail(args.xml_file, args.xmlid, output_dir)
    elif args.component == 'preview':
        preview_images(args.xml_file, args.xmlid, output_dir)
    elif args.component == 'mom':
        mom_static_problems(args.xml_file, args.xmlid, output_dir)
    elif args.component == 'all':
        if args.format == 'sagenb':
            # initialize  the converter
            xslt_executable = get_executable(config,  'xslt')
            _debug("xslt executable command: {}".format(xslt_executable))
            m2s = MathBookXMLtoSWS(xslt_exec=xslt_executable, mbx_dir=mbx_dir, xml_file=args.xml_file, sws_file=args.out)
            # Do the conversion
            m2s.convert()
        elif args.format == 'html':
            raise NotImplementedError("conversion to HTML version not integrated yet, use command line")
        elif args.format == 'latex':
            raise NotImplementedError("conversion to LaTeX version not integrated yet, use command line")
        else:
            raise NotImplementedError('cannot make entire document in "{}" format'.format(args.format))
    else:
        raise ValueError('the "{}" component is not a conversion option'.format(args.component))


if __name__ == "__main__":
    main()
