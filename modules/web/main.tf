data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

resource "aws_lb" "this" {
  name                       = substr("${var.name}-alb", 0, 32)
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [var.alb_security_group_id]
  subnets                    = var.public_subnet_ids
  enable_deletion_protection = false

  tags = merge(var.tags, { Name = "${var.name}-alb" })
}

resource "aws_lb_target_group" "this" {
  name        = substr("${var.name}-web", 0, 32)
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = merge(var.tags, { Name = "${var.name}-web-targets" })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = var.acm_certificate_arn == null ? "forward" : "redirect"
    target_group_arn = var.acm_certificate_arn == null ? aws_lb_target_group.this.arn : null

    dynamic "redirect" {
      for_each = var.acm_certificate_arn == null ? [] : [1]

      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }
}

resource "aws_lb_listener" "https" {
  count = var.acm_certificate_arn == null ? 0 : 1

  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = var.acm_certificate_arn
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

resource "aws_iam_role" "ec2" {
  name = "${var.name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.name}-ec2-profile"
  role = aws_iam_role.ec2.name
  tags = var.tags
}

resource "aws_launch_template" "this" {
  name_prefix            = "${var.name}-"
  image_id               = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  update_default_version = true

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  vpc_security_group_ids = [var.web_security_group_id]

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 30
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -eux
    dnf install -y nginx
    mkdir -p /usr/share/nginx/html
    cat > /usr/share/nginx/html/index.html <<'HTML'
    <!doctype html>
    <html lang="en">
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>Secure Terraform Web Lab</title>
        <style>
          :root {
            color-scheme: dark;
            font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
            background: #07111f;
            color: #f8fafc;
          }
          * { box-sizing: border-box; }
          body {
            margin: 0;
            min-height: 100vh;
            display: grid;
            place-items: center;
            padding: 2rem 1rem;
            background:
              radial-gradient(circle at 15% 15%, #2563eb55 0, transparent 32%),
              radial-gradient(circle at 85% 85%, #14b8a655 0, transparent 30%),
              linear-gradient(135deg, #07111f 0%, #101d35 48%, #0b2531 100%);
          }
          main {
            position: relative;
            overflow: hidden;
            width: min(760px, 100%);
            padding: clamp(2rem, 6vw, 4.5rem);
            border: 1px solid #ffffff22;
            border-radius: 1.75rem;
            background: linear-gradient(145deg, #172a46dd, #0f1c31dd);
            box-shadow: 0 2rem 5rem #02061788, inset 0 1px #ffffff1a;
            backdrop-filter: blur(18px);
          }
          main::after {
            content: "";
            position: absolute;
            width: 15rem;
            height: 15rem;
            top: -9rem;
            right: -6rem;
            border-radius: 50%;
            background: #38bdf822;
            filter: blur(8px);
          }
          .eyebrow { margin: 0 0 1.25rem; color: #7dd3fc; font-size: .78rem; font-weight: 800; letter-spacing: .18em; text-transform: uppercase; }
          .badge { display: inline-flex; align-items: center; gap: .55rem; padding: .5rem .8rem; border: 1px solid #34d39955; border-radius: 999px; background: #064e3b66; color: #a7f3d0; font-size: .85rem; font-weight: 750; }
          .badge::before { content: ""; width: .55rem; height: .55rem; border-radius: 50%; background: #34d399; box-shadow: 0 0 .75rem #34d399; }
          h1 { max-width: 12ch; margin: 1.4rem 0 1rem; color: #f8fafc; font-size: clamp(2.5rem, 8vw, 5rem); font-weight: 800; letter-spacing: -.065em; line-height: .98; }
          p { max-width: 54ch; margin: 0; color: #bfd0e5; font-size: clamp(1rem, 2vw, 1.15rem); line-height: 1.7; }
          ul { display: grid; gap: .8rem; margin: 2rem 0 0; padding: 1.25rem 1.25rem 1.25rem 2.5rem; border: 1px solid #ffffff12; border-radius: 1rem; background: #02061733; color: #dbeafe; line-height: 1.5; }
          li::marker { color: #67e8f9; }
          strong { color: #86efac; }
          .footer { margin-top: 1.75rem; color: #7f9bb8; font-size: .8rem; letter-spacing: .04em; }
          @media (max-width: 520px) { main { border-radius: 1.25rem; } h1 { font-size: 3.25rem; } }
        </style>
      </head>
      <body>
        <main>
          <p class="eyebrow">AWS infrastructure as code</p>
          <span class="badge">Infrastructure is working</span>
          <h1>Secure Terraform Web Lab</h1>
          <p>Your request reached a private EC2 web server through the public Application Load Balancer.</p>
          <ul>
            <li>Terraform-managed AWS infrastructure</li>
            <li>Private EC2 instance with SSM access</li>
            <li>ALB health check: <strong>healthy</strong></li>
          </ul>
          <div class="footer">Built with Terraform · Protected by AWS networking</div>
        </main>
      </body>
    </html>
    HTML
    echo 'ok' > /usr/share/nginx/html/health
    systemctl enable --now nginx
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { Name = "${var.name}-web" })
  }
}

resource "aws_autoscaling_group" "this" {
  name                = "${var.name}-web"
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity
  vpc_zone_identifier = var.private_subnet_ids
  health_check_type   = "ELB"
  target_group_arns   = [aws_lb_target_group.this.arn]

  launch_template {
    id      = aws_launch_template.this.id
    version = aws_launch_template.this.latest_version
  }

  tag {
    key                 = "Name"
    value               = "${var.name}-web"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
