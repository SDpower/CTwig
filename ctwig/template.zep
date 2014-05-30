/*
 * This file is part of CTwig.
 *
 * (c) 2014 Steve Lo
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

/**
 * Default base class for compiled templates.
 *
 * @author Steve Lo <info@sd.idv.tw>
 */

 namespace CTwig;

abstract class Template implements TemplateInterface
{
    const ANY_CALL    = "any";
    const ARRAY_CALL  = "array";
    const METHOD_CALL = "method";

	protected static cache;

    protected parent;
    protected parents;
    protected env;
    protected blocks;
    protected traits;

    /**
     * Constructor.
     *
     * @param CTwig\Environment $env A CTwig\Environment instance
     */
    public function __construct(<Environment> env)
    {
        let this->env = env;
        let this->blocks = [];
        let this->traits = [];
    }

    /**
     * Returns the template name.
     *
     * @return string The template name
     */
    abstract public function getTemplateName();

    /**
     * {@inheritdoc}
     */
    public function getEnvironment()
    {
        return this->env;
    }

    /**
     * Returns the parent template.
     *
     * This method is for internal use only and should never be called
     * directly.
     *
     * @return CTwig\TemplateInterface|false The parent template or false if there is no parent
     */
    public function getParent(array context)
    {
    	var parent, name;
        if (null !== this->parent) {
            return this->parent;
        }

        let parent = this->doGetParent(context);
        if (false === parent) {
            return false;
        } else {
	        if (parent instanceof \CTwig\Template) {
	            let name = parent->getTemplateName();
	            let this->parents[name] = parent;
	            let parent = name;
	        } else {
	        	if (!isset(this->parents[parent])) {
	            	let this->parents[parent] = this->env->loadTemplate(parent);
	            }
	        }        	
        }

        return this->parents[parent];
    }

    protected function doGetParent(array context)
    {
        return false;
    }

    public function isTraitable()
    {
        return true;
    }

    /**
     * Displays a parent block.
     *
     * This method is for internal use only and should never be called
     * directly.
     *
     * @param string $name    The block name to display from the parent
     * @param array  $context The context
     * @param array  $blocks  The current set of blocks
     */
    public function displayParentBlock(string name, array context, array blocks = [])
    {
        var parent;
        let name = (string) name;
        if (isset(this->traits[name])) {
            this->traits[name][0]->displayBlock(name, context, blocks, false);
        } else{
            let parent = this->getParent(context);
            if (false !== parent) {
                parent->displayBlock(name, context, blocks, false);
            } else {
                var msg;
                let msg = sprintf("The template has no parent and no traits defining the \"%s\" block", name);
                throw new \CTwig\Errors\Runtime(  msg, -1, this->getTemplateName());
            }
        }
    }

    /**
     * Displays a block.
     *
     * This method is for internal use only and should never be called
     * directly.
     *
     * @param string  $name      The block name to display
     * @param array   $context   The context
     * @param array   $blocks    The current set of blocks
     * @param bool    $useBlocks Whether to use the current set of blocks
     */
    public function displayBlock(name, array context, array blocks = [], useBlocks = true)
    {
        var template, block, e, parent, msg;
        let name = (string) name;
        if ( useBlocks && typeof blocks =="array" &&isset(blocks[name])) {
            let template = blocks[$name][0];
            let block = blocks[$name][1];
        } else {
            if (isset(this->blocks[name])) {
                let template = this->blocks[name][0];
                let block = this->blocks[name][1];
            } else {
                let template = null;
                let block = null;
            }
        }

        if (null !== template) {
            try {
                template->block(context, blocks);
            } catch \CTwig\Errors, e {
                throw e;
            } catch Exception, e {
                let msg = sprintf("An exception has been thrown during the rendering of a template (\"%s\").", e->getMessage());
                throw new \CTwig\Errors\Runtime(msg, -1, template->getTemplateName(), e);
            }
        } else {
            let parent = this->getParent(context);
            if (false !== parent) {
                parent->displayBlock(name, context, array_merge(this->blocks, blocks), false);
            }
        }

    }

    /**
     * Renders a parent block.
     *
     * This method is for internal use only and should never be called
     * directly.
     *
     * @param string $name    The block name to render from the parent
     * @param array  $context The context
     * @param array  $blocks  The current set of blocks
     *
     * @return string The rendered block
     */
    public function renderParentBlock(name, array context, array blocks = [])
    {
        ob_start();
        this->displayParentBlock(name, context, blocks);

        return ob_get_clean();
    }

    /**
     * Renders a block.
     *
     * This method is for internal use only and should never be called
     * directly.
     *
     * @param string  $name      The block name to render
     * @param array   $context   The context
     * @param array   $blocks    The current set of blocks
     * @param bool    $useBlocks Whether to use the current set of blocks
     *
     * @return string The rendered block
     */
    public function renderBlock(name, array context, array blocks = [], useBlocks = true)
    {
        ob_start();
        this->displayBlock(name, context, blocks, useBlocks);

        return ob_get_clean();
    }

    /**
     * Returns whether a block exists or not.
     *
     * This method is for internal use only and should never be called
     * directly.
     *
     * This method does only return blocks defined in the current template
     * or defined in "used" traits.
     *
     * It does not return blocks from parent templates as the parent
     * template name can be dynamic, which is only known based on the
     * current context.
     *
     * @param string $name The block name
     *
     * @return bool    true if the block exists, false otherwise
     */
    public function hasBlock(string name)
    {
        return isset(this->blocks[name]);
    }

    /**
     * Returns all block names.
     *
     * This method is for internal use only and should never be called
     * directly.
     *
     * @return array An array of block names
     *
     * @see hasBlock
     */
    public function getBlockNames()
    {
        return array_keys(this->blocks);
    }

    /**
     * Returns all blocks.
     *
     * This method is for internal use only and should never be called
     * directly.
     *
     * @return array An array of blocks
     *
     * @see hasBlock
     */
    public function getBlocks()
    {
        return this->blocks;
    }

    /**
     * {@inheritdoc}
     */
    public function display(array context, array blocks = [])
    {
        this->displayWithErrorHandling(this->env->mergeGlobals(context), blocks);
    }

    /**
     * {@inheritdoc}
     */
    public function render(array context)
    {
        var level, e;
        let level = ob_get_level();
        ob_start();
        try {
            this->display(context);
        } catch Exception ,e {
            while (ob_get_level() > level) {
                ob_end_clean();
            }

            throw e;
        }

        return ob_get_clean();
    }

    protected function displayWithErrorHandling(array context, array blocks = [])
    {
        var e;
        try {
            this->doDisplay(context, blocks);
        } catch \CTwig\Errors, e {
            if (!e->getTemplateFile()) {
                e->setTemplateFile(this->getTemplateName());
            }

            if (false === e->getTemplateLine()) {
                e->setTemplateLine(-1);
                e->guess();
            }

            throw e;
        } catch Exception, e {
            throw new \CTwig\Errors\Runtime(sprintf("An exception has been thrown during the rendering of a template (\"%s\").", e->getMessage()), -1, this->getTemplateName(), e);
        }
    }

    /**
     * Auto-generated method to display the template with the given context.
     *
     * @param array $context An array of parameters to pass to the template
     * @param array $blocks  An array of blocks to pass to the template
     */
    abstract protected function doDisplay(array context, array blocks = []);

    /**
     * Returns a variable from the context.
     *
     * This method is for internal use only and should never be called
     * directly.
     *
     * This method should not be overridden in a sub-class as this is an
     * implementation detail that has been introduced to optimize variable
     * access for versions of PHP before 5.4. This is not a way to override
     * the way to get a variable value.
     *
     * @param array   $context           The context
     * @param string  $item              The variable to return from the context
     * @param bool    $ignoreStrictCheck Whether to ignore the strict variable check or not
     *
     * @return The content of the context variable
     *
     * @throws Twig_Error_Runtime if the variable does not exist and Twig is running in strict mode
     */
    final protected function getContext(context, item, ignoreStrictCheck = false)
    {
        if (!array_key_exists(item, context)) {
            if (ignoreStrictCheck || !this->env->isStrictVariables()) {
                return;
            }

            throw new \CTwig\Errors\Runtime(sprintf("Variable \"%s\" does not exist", item), -1, this->getTemplateName());
        }

        return context[item];
    }

    /**
     * Returns the attribute value for a given array/object.
     *
     * @param mixed   $object            The object or array from where to get the item
     * @param mixed   $item              The item to get from the array or object
     * @param array   $arguments         An array of arguments to pass if the item is an object method
     * @param string  $type              The type of attribute (@see Twig_Template constants)
     * @param bool    $isDefinedTest     Whether this is only a defined check
     * @param bool    $ignoreStrictCheck Whether to ignore the strict attribute check or not
     *
     * @return mixed The attribute value, or a Boolean when $isDefinedTest is true, or null when the attribute is not set and $ignoreStrictCheck is true
     *
     * @throws Twig_Error_Runtime if the attribute does not exist and Twig is running in strict mode and $isDefinedTest is false
     */
    protected function getAttribute(objects, item, array arguments = [], types = self::ANY_CALL, isDefinedTest = false, ignoreStrictCheck = false)
    {
        var arrayItem, message, ret, classs, calls, lcItem, methods, e;
        //array
        if (typeof \CTwig\Template::METHOD_CALL !== typeof types) {
            let arrayItem = is_bool(item) || is_float(item) ? (int) item : item;

            if ( (is_array(objects) && array_key_exists(arrayItem, objects))
                //|| (objects instanceof \ArrayAccess && isset(objects[arrayItem]))
            ) {
                if (isDefinedTest) {
                    return true;
                }

                return objects[arrayItem];
            }

            if ( typeof \CTwig\Template::ARRAY_CALL === typeof types || !is_object(objects)) {
                if (isDefinedTest) {
                    return false;
                }

                if (ignoreStrictCheck || !this->env->isStrictVariables()) {
                    return;
                }

                if (objects instanceof ArrayAccess) {
                    let message = sprintf("Key \"%s\" in object with ArrayAccess of class \"%s\" does not exist", arrayItem, get_class(objects));
                } else {
                    if (is_object(objects)) {
                        let message = sprintf("Impossible to access a key \"%s\" on an object of class \"%s\" that does not implement ArrayAccess interface", item, get_class(objects));
                    } else {
                        if (typeof objects == "array") {
                                let message = sprintf("Key \"%s\" for array with keys \"%s\" does not exist", arrayItem, implode(', ', array_keys(objects)));
                        } else {
                            if (typeof \CTwig\Template::ARRAY_CALL === typeof types) {
                                let message = sprintf("Impossible to access a key (\"%s\") on a %s variable (\"%s\")", item, gettype(objects), objects);
                            } else {
                                let message = sprintf("Impossible to access an attribute (\"%s\") on a %s variable (\"%s\")", item, gettype(objects), objects);
                            }
                        }
                    }
                }
                throw new \CTwig\Errors\Runtime(message, -1, this->getTemplateName());
            }
        }

        if (!is_object(objects)) {
            if (isDefinedTest) {
                return false;
            }

            if (ignoreStrictCheck || !this->env->isStrictVariables()) {
                return;
            }

            throw new \CTwig\Errors\Runtime(sprintf("Impossible to invoke a method (\"%s\") on a %s variable (\"%s\")", item, gettype(objects), objects), -1, this->getTemplateName());
        }

        // object property
        if (typeof \CTwig\Template::ARRAY_CALL === typeof types) {
            if (isset(objects->item) || array_key_exists((string) item, objects)) {
                if (isDefinedTest) {
                    return true;
                }

                if (this->env->hasExtension("sandbox")) {
                    this->env->getExtension("sandbox")->checkPropertyAllowed(objects, item);
                }

                return objects->item;
            }
        }

        let classs = get_class(objects);

        // object method
        if (!isset(self::cache[classs]["methods"])) {
            let self::cache[classs]["methods"] = array_change_key_case(array_flip(get_class_methods(objects)));
        }

        let calls = false;
        let lcItem = item->lower();
        if (isset(self::cache[classs]["methods"][lcItem])) {
            let methods = (string) item;
        } else{
            if (isset(self::cache[classs]["methods"]["get".lcItem])) {
                let methods = "get" . item;
            } else {
                if (isset(self::cache[classs]["methods"]["is".lcItem])) {
                    let methods = "is" . item;
                } else {
                    if (isset(self::cache[classs]["methods"]["__call"])) {
                        let methods = (string) item;
                        let calls = true;
                    } else {
                        if (isDefinedTest) {
                            return false;
                        }

                        if (ignoreStrictCheck || !this->env->isStrictVariables()) {
                            return;
                        }

                        throw new \CTwig\Errors\Runtime(sprintf("Method \"%s\" for object \"%s\" does not exist", item, get_class(objects)), -1, this->getTemplateName());
                    }
                }
            }
        }

        if (isDefinedTest) {
            return true;
        }

        if (this->env->hasExtension("sandbox")) {
            this->env->getExtension("sandbox")->checkMethodAllowed(objects, methods);
        }

        // Some objects throw exceptions when they have __call, and the method we try
        // to call is not supported. If ignoreStrictCheck is true, we should return null.
        try {
            let ret = call_user_func_array([objects, methods], arguments);
        } catch BadMethodCallException, e {
            if (calls && (ignoreStrictCheck || !this->env->isStrictVariables())) {
                return;
            }
            throw e;
        }

        // useful when calling a template method from a template
        // this is not supported but unfortunately heavily used in the Symfony profiler
        if (objects instanceof \CTwig\TemplateInterface) {
            return ret === "" ? "" : new \CTwig\Markup(ret, this->env->getCharset());
        }

        return ret;
    }

    /**
     * This method is only useful when testing Twig. Do not use it.
     */
    public static function clearCache()
    {
        let self::cache = [];
    }
}