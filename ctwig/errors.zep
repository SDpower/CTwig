/*
 * This file is part of CTwig.
 *
 * (c) 2014 Steve Lo
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

/**
 * Twig base exception.
 *
 * This exception class and its children must only be used when
 * an error occurs during the loading of a template, when a syntax error
 * is detected in a template, or when rendering a template. Other
 * errors must use regular PHP exception classes (like when the template
 * cache directory is not writable for instance).
 *
 * To help debugging template issues, this class tracks the original template
 * name and line where the error occurred.
 *
 * Whenever possible, you must set these information (original template name
 * and line number) yourself by passing them to the constructor. If some or all
 * these information are not available from where you throw the exception, then
 * this class will guess them automatically (when the line number is set to -1
 * and/or the filename is set to null). As this is a costly operation, this
 * can be disabled by passing false for both the filename and the line number
 * when creating a new instance of this class.
 *
 * @author Steve Lo <info@sd.idv.tw>
 */
namespace CTwig;

class Errors extends \Exception
{
    protected lineno;
    protected filename;
    protected rawMessage;
    protected previous;

    /**
     * Constructor.
     *
     * Set both the line number and the filename to false to
     * disable automatic guessing of the original template name
     * and line number.
     *
     * Set the line number to -1 to enable its automatic guessing.
     * Set the filename to null to enable its automatic guessing.
     *
     * By default, automatic guessing is enabled.
     *
     * @param string    $message  The error message
     * @param int       $lineno   The template line where the error occurred
     * @param string    $filename The template file name where the error occurred
     * @param Exception $previous The previous exception
     */
    public function __construct(message, lineno = -1, filename = null, <\Exception> previous = null)
    {
        if (version_compare(PHP_VERSION, "5.3.0", "<")) {
            let this->previous = previous;
            parent::__construct("");
        } else {
            parent::__construct("", 0, previous);
        }

        let this->lineno = lineno;
        let this->filename = filename;

        if (-1 === this->lineno || null === this->filename) {
            this->guessTemplateInfo();
        }

        let this->rawMessage = message;

        this->updateRepr();
    }

    /**
     * Gets the raw message.
     *
     * @return string The raw message
     */
    public function getRawMessage()
    {
        return this->rawMessage;
    }

    /**
     * Gets the filename where the error occurred.
     *
     * @return string The filename
     */
    public function getTemplateFile()
    {
        return this->filename;
    }

    /**
     * Sets the filename where the error occurred.
     *
     * @param string $filename The filename
     */
    public function setTemplateFile(filename)
    {
        let this->filename = filename;

        this->updateRepr();
    }

    /**
     * Gets the template line where the error occurred.
     *
     * @return int     The template line
     */
    public function getTemplateLine()
    {
        return this->lineno;
    }

    /**
     * Sets the template line where the error occurred.
     *
     * @param int     $lineno The template line
     */
    public function setTemplateLine(lineno)
    {
        let this->lineno = lineno;

        this->updateRepr();
    }

    public function guess()
    {
        this->guessTemplateInfo();
        this->updateRepr();
    }

    /**
     * For PHP < 5.3.0, provides access to the getPrevious() method.
     *
     * @param string $method    The method name
     * @param array  $arguments The parameters to be passed to the method
     *
     * @return Exception The previous exception or null
     *
     * @throws BadMethodCallException
     */
    public function __call(method, arguments)
    {
        var getprevious = "getprevious";
        if (getprevious == strtolower(method)) {
            return this->previous;
        }

        throw new \BadMethodCallException(sprintf("Method \"CTwig\Error::%s()\" does not exist.", method));
    }

    protected function updateRepr()
    {
        var dot, filename, definition;
        let this->message = this->rawMessage;

        let dot = false;
        let definition = ".";
        if (definition === substr(this->message, -1)) {
            let this->message = substr(this->message, 0, -1);
            let dot = true;
        }

        if (this->filename) {
            if (is_string(this->filename) || (is_object(this->filename) && method_exists(this->filename, "__toString"))) {
                let filename = sprintf("\"%s\"", this->filename);
            } else {
                let filename = json_encode(this->filename);
            }
            let this->message .= sprintf(" in %s", filename);
        }

        if (this->lineno && this->lineno >= 0) {
            let this->message .= sprintf(" at line %d", this->lineno);
        }

        if (dot) {
            let this->message .= ".";
        }
    }

    protected function guessTemplateInfo()
    {
        var template, templateClass, backtrace, trace, key, r, file, definition, currentClass, isEmbedContainer,
        e, exceptions, traces, vtrace, templateLine, codeLine;
        let template = null;
        let templateClass = null;

        if (version_compare(phpversion(), "5.3.6", ">=")) {
            let backtrace = debug_backtrace(DEBUG_BACKTRACE_IGNORE_ARGS | DEBUG_BACKTRACE_PROVIDE_OBJECT);
        } else {
            let backtrace = debug_backtrace();
        }

        if typeof backtrace == "array" {
            var CTwigTemplate = "CTwig\\Template";
            for key, trace in backtrace {
                let definition = trace["object"];
                if typeof definition == "object" {
                    if ((definition instanceof \CTwig\Template) &&
                        (CTwigTemplate !== get_class(definition)) ){       
                        let currentClass = get_class(definition);                 
                        let isEmbedContainer = 0 === strpos(templateClass, currentClass);
                        if (null === this->filename || (this->filename == definition->getTemplateName() && !isEmbedContainer)) {
                            let template = definition;
                            let templateClass = get_class(definition);
                        }
                    }
                }
            }
        }

        // update template filename
        if (null !== template && null === this->filename) {
            let this->filename = template->getTemplateName();
        }

        if (null === template || this->lineno > -1) {
            return;
        }

        let r = new \ReflectionObject(template);
        let file = r->getFileName();

        // hhvm has a bug where eval'ed files comes out as the current directory
        if (is_dir(file)) {
            let file = "";
        }

        let exceptions = [ this ];
        let e = this;
        while (((e instanceof \CTwig\Errors) || method_exists(e, "getPrevious")) && e == e->getPrevious()) {
            let exceptions[] = e;
        }
        let e = true;
        while (!is_null(e)) {
            let e = array_pop(exceptions);
            if (!is_null(e)){
                let traces = e->getTrace();
                let vtrace = true;
                while (!is_null(vtrace)) {
                    let vtrace = array_shift(traces);
                    if (!is_null(vtrace)){
                        if (!isset(vtrace["file"]) || !isset(vtrace["line"]) || file != vtrace["file"]) {
                            continue;
                        }

                        for codeLine, templateLine in template {
                            if (codeLine <= vtrace["line"]) {
                                // update template line
                                let this->lineno = templateLine;

                                return;
                            }
                        }
                    }
                }
            }
        }
    }
}
