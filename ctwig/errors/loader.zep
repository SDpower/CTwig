/*
 * This file is part of CTwig.
 *
 * (c) 2014 Steve Lo
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

/**
 * Exception thrown when an error occurs during template loading.
 *
 * Automatic template information guessing is always turned off as
 * if a template cannot be loaded, there is nothing to guess.
 * However, when a template is loaded from another one, then, we need
 * to find the current context and this is automatically done by
 * CTwig\Template::displayWithErrorHandling().
 *
 * This strategy makes CTwig\Environment::resolveTemplate() much faster.
 *
 * @author Steve Lo <info@sd.idv.tw>
 */
namespace CTwig\Errors;
class Loader extends \CTwig\Errors
{
    public function __construct(message, lineno = -1, filename = null, <\Exception> previous = null)
    {
        parent::__construct(message, false, false, previous);
    }
}
