/*
 * This file is part of CTwig.
 *
 * (c) 2014 Steve Lo
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

/**
 * Loads a template from an array.
 *
 * When using this loader with a cache mechanism, you should know that a new cache
 * key is generated each time a template content "changes" (the cache key being the
 * source code of the template). If you don't want to see your cache grows out of
 * control, you need to take care of clearing the old cache file by yourself.
 *
 * @author Steve Lo <info@sd.idv.tw>
 */
namespace CTwig\Loader;

class Arrays implements \CTwig\LoaderInterface, \CTwig\ExistsLoaderInterface
{
    protected templates = [];

    /**
     * Constructor.
     *
     * @param array $templates An array of templates (keys are the names, and values are the source code)
     *
     * @see CTwig\Loader
     */
    public function __construct(array templates)
    {
        if typeof templates != "array" {
            throw new \CTwig\Errors\Loader("An array is required as templates param");
        }
        let this->templates = templates;
    }

    /**
     * Adds or overrides a template.
     *
     * @param string $name     The template name
     * @param string $template The template source
     */
    public function setTemplate(string name, template)
    {
        let this->templates[name] = template;
    }

    /**
     * {@inheritdoc}
     */
    public function getSource(string name)
    {
        if (!isset(this->templates[name])) {
            throw new \CTwig\Errors\Loader(sprintf("Template \"%s\" is not defined.", name));
        }

        return this->templates[name];
    }

    /**
     * {@inheritdoc}
     */
    public function exists(string name)
    {
        return isset(this->templates[name]);
    }

    /**
     * {@inheritdoc}
     */
    public function getCacheKey(string name)
    {
        if (!isset(this->templates[name])) {
            throw new \CTwig\Errors\Loader(sprintf("Template \"%s\" is not defined.", name));
        }

        return this->templates[name];
    }

    /**
     * {@inheritdoc}
     */
    public function isFresh(name, time)
    {
        if (!isset(this->templates[name])) {
            throw new \CTwig\Errors\Loader(sprintf("Template \"%s\" is not defined.", name));
        }

        return true;
    }
}
