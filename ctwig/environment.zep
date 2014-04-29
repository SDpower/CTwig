/*
 * This file is part of CTwig.
 *
 * (c) 2014 Steve Lo
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

/**
 * Stores the CTwig configuration.
 *
 * @author Steve Lo <info@sd.idv.tw>
 */

namespace CTwig;

class Environment
{
	const TYPE_INTEGER = "1.15.2-DEV";

	protected _charset;
    protected _loader;
    protected _debug;
    protected _autoReload;
    protected _cache;
    protected _lexer;
    protected _parser;
    protected _compiler;

    //Set or Get base template class for compiled templates.
    protected _baseTemplateClass { set, get };
    protected _extensions;
    protected _parsers;
    protected _visitors;
    protected _filters;
    protected _tests;
    protected _functions;
    protected _globals;
    protected _runtimeInitialized;
    protected _extensionInitialized;
    protected _loadedTemplates;
    protected _strictVariables;
    protected _unaryOperators;
    protected _binaryOperators;
    protected _templateClassPrefix = "__TwigTemplate_";
    protected _functionCallbacks;
    protected _filterCallbacks;
    protected _staging;

    /**
     * Constructor.
     *
     * Available options:
     *
     *  * debug: When set to true, it automatically set "auto_reload" to true as
     *           well (default to false).
     *
     *  * charset: The charset used by the templates (default to UTF-8).
     *
     *  * base_template_class: The base template class to use for generated
     *                         templates (default to Twig_Template).
     *
     *  * cache: An absolute path where to store the compiled templates, or
     *           false to disable compilation cache (default).
     *
     *  * auto_reload: Whether to reload the template if the original source changed.
     *                 If you don't provide the auto_reload option, it will be
     *                 determined automatically based on the debug value.
     *
     *  * strict_variables: Whether to ignore invalid variables in templates
     *                      (default to false).
     *
     *  * autoescape: Whether to enable auto-escaping (default to html):
     *                  * false: disable auto-escaping
     *                  * true: equivalent to html
     *                  * html, js: set the autoescaping to one of the supported strategies
     *                  * PHP callback: a PHP callback that returns an escaping strategy based on the template "filename"
     *
     *  * optimizations: A flag that indicates which optimizations to apply
     *                   (default to -1 which means that all optimizations are enabled;
     *                   set it to 0 to disable).
     *
     * @param CTwig_LoaderInterface $loader  A CTwig\LoaderInterface instance
     * @param array                $options An array of options
     */
	public function __construct(options=null)
	{
        var default_options;
        let default_options = [
            "debug"               : false,
            "charset"             : "UTF-8",
            "base_template_class" : "Twig_Template",
            "strict_variables"    : false,
            "autoescape"          : "html",
            "cache"               : false,
            "auto_reload"         : null,
            "optimizations"       : -1
            ];
        if typeof options != "array" {
            let options = default_options;
        } else {
            let options = array_merge(default_options, options);
        }
        		
		let this->_debug              = (bool) options["debug"];
	    let this->_charset            = strtoupper(options["charset"]);
	    let this->_baseTemplateClass  = options["base_template_class"];
	    let this->_autoReload         = null === options["auto_reload"] ? this->_debug : (bool) options["auto_reload"];
	    let this->_strictVariables    = (bool) options["strict_variables"];
	    let this->_runtimeInitialized = false;
	    // let this->setCache(options["cache"]);
	    let this->_functionCallbacks = [];
	    let this->_filterCallbacks = [];
	}

    // let this->addExtension(new Twig_Extension_Core());
    // let this->addExtension(new Twig_Extension_Escaper($options['autoescape']));
    // let this->addExtension(new Twig_Extension_Optimizer($options['optimizations']));
    // let this->extensionInitialized = false;
    // let this->staging = new Twig_Extension_Staging();


    /**
     * Enables debugging mode.
     */
    public function enableDebug() -> void
    {
        let this->_debug = true;
    }

    /**
     * Disables debugging mode.
     */
    public function disableDebug() -> void
    {
        let this->_debug = false;
    }

    /**
     * Checks if debug mode is enabled.
     *
     * @return bool    true if debug mode is enabled, false otherwise
     */
    public function isDebug() -> bool
    {
        return this->_debug;
    }

    /**
     * Enables the auto_reload option.
     */
    public function enableAutoReload() -> void
    {
        let this->_autoReload = true;
    }

    /**
     * Disables the auto_reload option.
     */
    public function disableAutoReload() -> void
    {
        let this->_autoReload = false;
    }

    /**
     * Checks if the auto_reload option is enabled.
     *
     * @return bool    true if auto_reload is enabled, false otherwise
     */
    public function isAutoReload() -> bool
    {
        return this->_autoReload;
    }

    /**
     * Enables the strict_variables option.
     */
    public function enableStrictVariables() -> void
    {
        let this->_strictVariables = true;
    }

    /**
     * Disables the strict_variables option.
     */
    public function disableStrictVariables() -> void
    {
        let this->_strictVariables = false;
    }

    /**
     * Checks if the strict_variables option is enabled.
     *
     * @return bool    true if strict_variables is enabled, false otherwise
     */
    public function isStrictVariables() -> bool
    {
        return this->_strictVariables;
    }

    /**
     * Gets the cache directory or false if cache is disabled.
     *
     * @return string|false
     */
    public function getCache()
    {
        return this->_cache;
    }

     /**
      * Sets the cache directory or false if cache is disabled.
      *
      * @param string|false $cache The absolute path to the compiled templates,
      *                            or false to disable cache
      */
    public function setCache(cache)
    {
        let this->_cache = cache ? cache : false;
    }    

    /**
     * Gets the template class associated with the given string.
     *
     * @param string  $name  The name for which to calculate the template class name
     * @param int     $index The index if it is an embedded template
     *
     * @return string The template class name
     */
    public function getTemplateClass(name, index = null)
    {
    	return this->_templateClassPrefix . hash("sha256", "123213");
        //return this->_templateClassPrefix.hash('sha256', $this->getLoader()->getCacheKey(name)).(null === index ? '' : '_'.index);
    }

    /**
     * Gets the template class prefix.
     *
     * @return string The template class prefix
     */
    public function getTemplateClassPrefix()
    {
        return this->_templateClassPrefix;
    }

    /**
     * Gets the cache filename for a given template.
     *
     * @param string $name The template name
     *
     * @return string|false The cache file name or false when caching is disabled
     */
    public function getCacheFilename(name)
    {
    	var className;
        if (false === this->_cache) {
            return false;
        }

        let className = substr( this->getTemplateClass(name), strlen( this->_templateClassPrefix ));

        return this->getCache()."/".substr(className, 0, 2)."/".substr(className, 2, 2)."/".substr(className, 4).".php";
    }
}