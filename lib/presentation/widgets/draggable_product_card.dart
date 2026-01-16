import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/product_model.dart';

class DraggableProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onDelete;
  final Widget child;

  const DraggableProductCard({
    super.key,
    required this.product,
    required this.onDelete,
    required this.child,
  });

  @override
  State<DraggableProductCard> createState() => _DraggableProductCardState();
}

class _DraggableProductCardState extends State<DraggableProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragExtent = 0;
  final double _deleteThreshold = 80;

  late Animation<double> _sizeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0, // Start fully visible
    );
    _sizeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleDelete() async {
    await _controller.reverse();
    widget.onDelete();
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Delete Product'),
          content: Text(
            'Are you sure you want to delete "${widget.product.title}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      _handleDelete();
    } else {
      // Reset drag (animate back to closed)
      setState(() {
        _dragExtent = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _sizeAnimation,
      axisAlignment: -1.0, // Collapse upwards
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          // Allow dragging to the left
          if (details.primaryDelta! < 0 || _dragExtent < 0) {
            setState(() {
              _dragExtent += details.primaryDelta!;
              // Clamp
              if (_dragExtent > 0) _dragExtent = 0;
              if (_dragExtent < -120) _dragExtent = -120;
            });
          }
        },
        onHorizontalDragEnd: (details) {
          if (_dragExtent < -_deleteThreshold / 2) {
            // Snap to open
            setState(() {
              _dragExtent = -_deleteThreshold;
            });
          } else {
            // Snap back to close
            setState(() {
              _dragExtent = 0;
            });
          }
        },
        child: Stack(
          children: [
            // Background (Delete Button)
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.symmetric(
                  vertical: 0,
                ), // Match child margin/padding if needed
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [Colors.red.shade400, AppColors.error],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                child: InkWell(
                  onTap: () {
                    if (_dragExtent <= -_deleteThreshold) {
                      _showDeleteConfirmation(context);
                    }
                  },
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),

            // Foreground (Child)
            Transform.translate(
              offset: Offset(_dragExtent, 0),
              child: widget.child,
            ),
          ],
        ),
      ),
    );
  }
}
