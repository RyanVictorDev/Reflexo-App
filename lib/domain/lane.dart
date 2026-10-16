enum Lane { left, right }

extension LaneSide on Lane {
  Lane get opposite => this == Lane.left ? Lane.right : Lane.left;
}
