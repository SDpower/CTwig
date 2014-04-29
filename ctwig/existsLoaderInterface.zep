/*
 * This file is part of CTwig.
 *
 * (c) 2014 Steve Lo
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

/**
 * Adds an exists() method for loaders.
 *
 * @author Steve Lo <info@sd.idv.tw>
 * @deprecated since 1.12 (to be removed in 2.0)
 */
namespace CTwig;

interface ExistsLoaderInterface
{
    /**
     * Check if we have the source code of a template, given its name.
     *
     * @param string $name The name of the template to check if we can load
     *
     * @return bool    If the template source code is handled by this loader or not
     */
    public function exists($name);
}
