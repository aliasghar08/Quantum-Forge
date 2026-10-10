import torch

def test_mps_basic():
    device = torch.device("mps")
    x = torch.randn(4, 8, device=device, requires_grad=True)
    y = (x ** 2).sum()
    y.backward()
    assert x.grad is not None
    assert torch.isfinite(x.grad).all()
    print("Basic MPS autograd: PASS")

def test_mps_second_order():
    device = torch.device("mps")
    x = torch.randn(4, 3, device=device, requires_grad=True)
    y = (x ** 3).sum()
    g = torch.autograd.grad(y, x, create_graph=True)[0]
    g2 = torch.autograd.grad(g.sum(), x, retain_graph=False)[0]
    assert torch.isfinite(g2).all(), "Second-order grad is NaN/inf on MPS"
    print("Second-order MPS autograd: PASS")

if __name__ == "__main__":
    test_mps_basic()
    test_mps_second_order()
