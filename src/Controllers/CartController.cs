using Microsoft.AspNetCore.Mvc;
using ZavaStorefront.Services;

namespace ZavaStorefront.Controllers
{
    public class CartController : Controller
    {
        private readonly ILogger<CartController> _logger;
        private readonly CartService _cartService;
        private readonly ContentSafetyService _contentSafetyService;

        public CartController(ILogger<CartController> logger, CartService cartService, ContentSafetyService contentSafetyService)
        {
            _logger = logger;
            _cartService = cartService;
            _contentSafetyService = contentSafetyService;
        }

        private async Task<bool> IsUserInputSafeAsync(string userInput)
        {
            var (isSafe, log) = await _contentSafetyService.EvaluateTextAsync(userInput);
            if (!isSafe)
            {
                _logger.LogWarning("Blocked unsafe user input: {Log}", log);
            }
            return isSafe;
        }

        public IActionResult Index()
        {
            _logger.LogInformation("Loading cart page with {ItemCount} items", _cartService.GetCartItemCount());
            var cart = _cartService.GetCart();
            ViewBag.CartTotal = _cartService.GetCartTotal();
            return View(cart);
        }

        [HttpPost]
        public IActionResult UpdateQuantity(int productId, int quantity)
        {
            _logger.LogInformation("Updating product {ProductId} quantity to {Quantity}", productId, quantity);
            _cartService.UpdateQuantity(productId, quantity);
            return RedirectToAction("Index");
        }

        [HttpPost]
        public IActionResult RemoveFromCart(int productId)
        {
            _logger.LogInformation("Removing product {ProductId} from cart", productId);
            _cartService.RemoveFromCart(productId);
            return RedirectToAction("Index");
        }

        [HttpPost]
        public IActionResult Checkout()
        {
            var itemCount = _cartService.GetCartItemCount();
            var total = _cartService.GetCartTotal();
            _logger.LogInformation("Processing checkout for {ItemCount} items, total: {Total:C}", itemCount, total);
            _cartService.ClearCart();
            return RedirectToAction("CheckoutSuccess");
        }

        public IActionResult CheckoutSuccess()
        {
            _logger.LogInformation("Displaying checkout success page");
            return View();
        }

        public int GetCartCount()
        {
            return _cartService.GetCartItemCount();
        }
    }
}
